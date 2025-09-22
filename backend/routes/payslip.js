const express = require('express');
const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');
const database = require('../config/database');
const router = express.Router();
const auth = require('../middleware/auth');

// =====================================================================
// PAYSLIP GENERATION AND MANAGEMENT
// =====================================================================

// Generate payslip for a staff member for a specific month/year
router.get('/generate/:staff_id/:year/:month', auth, async (req, res) => {
    try {
        const { staff_id, year, month } = req.params;

        // Get staff details
        const staff = await database.query(`
            SELECT a.*, sp.*, sb.*, ss.*
            FROM admissions a
            LEFT JOIN staff_personal sp ON a.staff_id = sp.staff_id
            LEFT JOIN staff_banking sb ON a.staff_id = sb.staff_id
            LEFT JOIN staff_salary ss ON a.staff_id = ss.staff_id
            WHERE a.staff_id = ? OR a.id = ?
        `, [staff_id, staff_id]);

        if (staff.length === 0) {
            return res.status(404).json({ message: 'Staff member not found' });
        }

        const staffData = staff[0];

        // Get attendance data for the month
        const attendance = await database.query(`
            SELECT * FROM attendance_records 
            WHERE staff_id = ? AND year = ? AND month = ?
        `, [staff_id, year, month]);

        const attendanceData = attendance[0] || {
            days_present: 0,
            days_absent: 0,
            overtime_hours: 0
        };

        // Get deductions data
        const deductions = await database.query(`
            SELECT * FROM staff_deductions_comprehensive 
            WHERE staff_id = ?
        `, [staff_id]);

        const deductionData = deductions[0] || {};

        // Calculate salary components
        const salaryComponents = await calculateSalaryComponents(staffData, attendanceData, deductionData, year, month);

        // Check if payslip already exists
        const existingPayslip = await database.query(`
            SELECT * FROM payslips 
            WHERE staff_id = ? AND year = ? AND month = ?
        `, [staff_id, year, month]);

        let payslipId;
        if (existingPayslip.length > 0) {
            // Update existing payslip
            payslipId = existingPayslip[0].id;
            await database.run(`
                UPDATE payslips SET 
                basic_pay = ?, da = ?, hra = ?, special_pay = ?, 
                special_allowance = ?, other_allowance = ?, gross_salary = ?,
                total_deductions = ?, net_salary = ?, days_present = ?, days_absent = ?,
                updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
            `, [
                salaryComponents.basic_pay, salaryComponents.da, salaryComponents.hra,
                salaryComponents.special_pay, salaryComponents.special_allowance,
                salaryComponents.other_allowance, salaryComponents.gross_salary,
                salaryComponents.total_deductions, salaryComponents.net_salary,
                attendanceData.days_present, attendanceData.days_absent, payslipId
            ]);
        } else {
            // Create new payslip
            const result = await database.run(`
                INSERT INTO payslips (
                    staff_id, month, year, basic_pay, da, hra, special_pay,
                    special_allowance, other_allowance, gross_salary, total_deductions,
                    net_salary, days_present, days_absent, generated_by
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `, [
                staff_id, month, year, salaryComponents.basic_pay, salaryComponents.da,
                salaryComponents.hra, salaryComponents.special_pay, salaryComponents.special_allowance,
                salaryComponents.other_allowance, salaryComponents.gross_salary,
                salaryComponents.total_deductions, salaryComponents.net_salary,
                attendanceData.days_present, attendanceData.days_absent, req.user.userId
            ]);
            payslipId = result.lastID;
        }

        // Get complete payslip data
        const payslip = await database.query(`
            SELECT p.*, a.name as staff_name, a.designation, sp.father_name
            FROM payslips p
            JOIN admissions a ON p.staff_id = a.staff_id
            LEFT JOIN staff_personal sp ON p.staff_id = sp.staff_id
            WHERE p.id = ?
        `, [payslipId]);

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, 'generate', 'payslip', payslipId, `Generated payslip for ${staffData.name || staffData.staff_name} - ${month}/${year}`, req.ip]
        );

        res.json({
            success: true,
            message: 'Payslip generated successfully',
            payslip: {
                ...payslip[0],
                salary_components: salaryComponents,
                deductions_breakdown: getDeductionsBreakdown(deductionData),
                attendance_info: attendanceData
            }
        });

    } catch (error) {
        console.error('Generate payslip error:', error);
        res.status(500).json({ message: 'Failed to generate payslip' });
    }
});

// Get payslip history for a staff member
router.get('/history/:staff_id', auth, async (req, res) => {
    try {
        const { staff_id } = req.params;
        const { year, limit = 12 } = req.query;

        let query = `
            SELECT p.*, a.name as staff_name, a.designation
            FROM payslips p
            JOIN admissions a ON p.staff_id = a.staff_id
            WHERE p.staff_id = ?
        `;
        const params = [staff_id];

        if (year) {
            query += ' AND p.year = ?';
            params.push(year);
        }

        query += ' ORDER BY p.year DESC, p.month DESC LIMIT ?';
        params.push(parseInt(limit));

        const payslips = await database.query(query, params);

        // Get staff details
        const staff = await database.query(
            'SELECT * FROM admissions WHERE staff_id = ? OR id = ?',
            [staff_id, staff_id]
        );

        res.json({
            success: true,
            staff: staff[0] || null,
            payslips: payslips
        });

    } catch (error) {
        console.error('Get payslip history error:', error);
        res.status(500).json({ message: 'Failed to retrieve payslip history' });
    }
});

// Download payslip as PDF
router.get('/pdf/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;

        // Get payslip data
        const payslip = await database.query(`
            SELECT p.*, a.name as staff_name, a.designation, a.staff_id as emp_id,
                   sp.father_name, sb.bank_name, sb.account_number
            FROM payslips p
            JOIN admissions a ON p.staff_id = a.staff_id
            LEFT JOIN staff_personal sp ON p.staff_id = sp.staff_id
            LEFT JOIN staff_banking sb ON p.staff_id = sb.staff_id
            WHERE p.id = ?
        `, [id]);

        if (payslip.length === 0) {
            return res.status(404).json({ message: 'Payslip not found' });
        }

        const payslipData = payslip[0];

        // Get deductions data
        const deductions = await database.query(`
            SELECT * FROM staff_deductions_comprehensive 
            WHERE staff_id = ?
        `, [payslipData.staff_id]);

        // Create PDF
        const pdfPath = await generatePayslipPDF(payslipData, deductions[0] || {});

        // Set response headers for PDF download
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', `attachment; filename="payslip_${payslipData.staff_name}_${payslipData.month}_${payslipData.year}.pdf"`);

        // Stream the PDF file
        const fileStream = fs.createReadStream(pdfPath);
        fileStream.pipe(res);

        // Clean up the temporary file after streaming
        fileStream.on('end', () => {
            fs.unlink(pdfPath, (err) => {
                if (err) console.error('Error deleting temporary PDF file:', err);
            });
        });

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, 'download', 'payslip', id, `Downloaded payslip PDF for ${payslipData.staff_name}`, req.ip]
        );

    } catch (error) {
        console.error('Download payslip PDF error:', error);
        res.status(500).json({ message: 'Failed to download payslip PDF' });
    }
});

// Calculate salary components for a staff member
router.post('/calculate', auth, async (req, res) => {
    try {
        const {
            staff_id,
            year,
            month,
            days_present,
            days_absent,
            overtime_hours,
            additional_allowances,
            additional_deductions
        } = req.body;

        // Get staff details
        const staff = await database.query(`
            SELECT a.*, sp.*, sb.*, ss.*
            FROM admissions a
            LEFT JOIN staff_personal sp ON a.staff_id = sp.staff_id
            LEFT JOIN staff_banking sb ON a.staff_id = sb.staff_id
            LEFT JOIN staff_salary ss ON a.staff_id = ss.staff_id
            WHERE a.staff_id = ? OR a.id = ?
        `, [staff_id, staff_id]);

        if (staff.length === 0) {
            return res.status(404).json({ message: 'Staff member not found' });
        }

        const staffData = staff[0];

        // Get deductions data
        const deductions = await database.query(`
            SELECT * FROM staff_deductions_comprehensive 
            WHERE staff_id = ?
        `, [staff_id]);

        const deductionData = deductions[0] || {};

        // Mock attendance data with provided values
        const attendanceData = {
            days_present: days_present || 0,
            days_absent: days_absent || 0,
            overtime_hours: overtime_hours || 0
        };

        // Calculate salary components
        const salaryComponents = await calculateSalaryComponents(
            staffData, 
            attendanceData, 
            deductionData, 
            year, 
            month,
            additional_allowances,
            additional_deductions
        );

        res.json({
            success: true,
            staff_id: staff_id,
            calculation_date: new Date().toISOString(),
            salary_components: salaryComponents,
            deductions_breakdown: getDeductionsBreakdown(deductionData),
            attendance_info: attendanceData
        });

    } catch (error) {
        console.error('Calculate salary error:', error);
        res.status(500).json({ message: 'Failed to calculate salary' });
    }
});

// Get salary summary for a staff member
router.get('/summary/:staff_id', auth, async (req, res) => {
    try {
        const { staff_id } = req.params;
        const { year } = req.query;
        const currentYear = year || new Date().getFullYear();

        // Get yearly payslip summary
        const yearlySummary = await database.query(`
            SELECT 
                COUNT(*) as total_months,
                SUM(basic_pay) as total_basic_pay,
                SUM(gross_salary) as total_gross_salary,
                SUM(total_deductions) as total_deductions,
                SUM(net_salary) as total_net_salary,
                AVG(days_present) as avg_attendance,
                MAX(net_salary) as highest_net_salary,
                MIN(net_salary) as lowest_net_salary
            FROM payslips 
            WHERE staff_id = ? AND year = ?
        `, [staff_id, currentYear]);

        // Get monthly breakdown
        const monthlyBreakdown = await database.query(`
            SELECT month, basic_pay, gross_salary, total_deductions, net_salary, days_present
            FROM payslips 
            WHERE staff_id = ? AND year = ? 
            ORDER BY month
        `, [staff_id, currentYear]);

        // Get staff details
        const staff = await database.query(
            'SELECT * FROM admissions WHERE staff_id = ? OR id = ?',
            [staff_id, staff_id]
        );

        res.json({
            success: true,
            staff: staff[0] || null,
            year: parseInt(currentYear),
            yearly_summary: yearlySummary[0],
            monthly_breakdown: monthlyBreakdown
        });

    } catch (error) {
        console.error('Get salary summary error:', error);
        res.status(500).json({ message: 'Failed to retrieve salary summary' });
    }
});

// =====================================================================
// HELPER FUNCTIONS
// =====================================================================

// Calculate salary components
async function calculateSalaryComponents(staffData, attendanceData, deductionData, year, month, additionalAllowances = {}, additionalDeductions = {}) {
    try {
        // Base salary calculation
        const basicPay = parseFloat(staffData.basic_pay || staffData.basic_salary || 0);
        const daPercentage = parseFloat(staffData.da_percentage || 42); // Default DA
        const hraPercentage = parseFloat(staffData.hra_percentage || 24); // Default HRA
        
        // Calculate allowances
        const da = (basicPay * daPercentage) / 100;
        const hra = (basicPay * hraPercentage) / 100;
        const specialPay = parseFloat(staffData.special_pay || 0);
        const specialAllowance = parseFloat(staffData.special_allowance || 0);
        const otherAllowance = parseFloat(staffData.other_allowance || 0);
        
        // Additional allowances
        const additionalAllowanceAmount = Object.values(additionalAllowances).reduce((sum, val) => sum + parseFloat(val || 0), 0);
        
        // Calculate gross salary
        const grossSalary = basicPay + da + hra + specialPay + specialAllowance + otherAllowance + additionalAllowanceAmount;
        
        // Calculate attendance-based deduction
        const totalWorkingDays = 30; // Assume 30 working days per month
        const attendanceDeduction = attendanceData.days_absent > 0 ? 
            (basicPay / totalWorkingDays) * attendanceData.days_absent : 0;
        
        // Standard deductions
        const pf = basicPay * 0.12; // 12% PF
        const esi = grossSalary <= 25000 ? grossSalary * 0.0175 : 0; // 1.75% ESI if salary <= 25000
        const professionalTax = grossSalary > 10000 ? 200 : 0; // Standard PT
        
        // Custom deductions from deduction data
        const customDeductions = {
            gpf_monthly: parseFloat(deductionData.gpf_government_contribution_monthly || 0),
            lic_monthly: parseFloat(deductionData.lic_monthly || 0),
            gic_monthly: parseFloat(deductionData.gic_monthly || 0),
            electricity_monthly: parseFloat(deductionData.electricity_bill_monthly || 0),
            water_charges_monthly: parseFloat(deductionData.water_charges_monthly || 0),
            recovery_monthly: parseFloat(deductionData.recovery_monthly || 0),
            leave_deductions_monthly: parseFloat(deductionData.leave_deductions_monthly || 0),
            income_tax_monthly: parseFloat(deductionData.income_tax_monthly || 0),
            other_deduction_1_monthly: parseFloat(deductionData.other_deduction_1_monthly || 0),
            other_deduction_2_monthly: parseFloat(deductionData.other_deduction_2_monthly || 0),
            other_deduction_3_monthly: parseFloat(deductionData.other_deduction_3_monthly || 0)
        };
        
        const totalCustomDeductions = Object.values(customDeductions).reduce((sum, val) => sum + val, 0);
        const additionalDeductionAmount = Object.values(additionalDeductions).reduce((sum, val) => sum + parseFloat(val || 0), 0);
        
        // Total deductions
        const totalDeductions = attendanceDeduction + pf + esi + professionalTax + totalCustomDeductions + additionalDeductionAmount;
        
        // Net salary
        const netSalary = Math.max(0, grossSalary - totalDeductions);
        
        return {
            basic_pay: basicPay,
            da: da,
            hra: hra,
            special_pay: specialPay,
            special_allowance: specialAllowance,
            other_allowance: otherAllowance,
            additional_allowances: additionalAllowanceAmount,
            gross_salary: grossSalary,
            
            // Deductions breakdown
            attendance_deduction: attendanceDeduction,
            provident_fund: pf,
            esi: esi,
            professional_tax: professionalTax,
            custom_deductions: customDeductions,
            additional_deductions: additionalDeductionAmount,
            total_deductions: totalDeductions,
            
            net_salary: netSalary
        };
        
    } catch (error) {
        console.error('Calculate salary components error:', error);
        throw error;
    }
}

// Get deductions breakdown
function getDeductionsBreakdown(deductionData) {
    return {
        gpf: {
            total: parseFloat(deductionData.gpf_government_contribution_total || 0),
            monthly: parseFloat(deductionData.gpf_government_contribution_monthly || 0)
        },
        nps: {
            govt_total: parseFloat(deductionData.nps_government_contribution_total || 0),
            govt_monthly: parseFloat(deductionData.nps_government_contribution_monthly || 0),
            self_total: parseFloat(deductionData.nps_self_contribution_total || 0),
            self_monthly: parseFloat(deductionData.nps_self_contribution_monthly || 0)
        },
        insurance: {
            lic_total: parseFloat(deductionData.lic_total || 0),
            lic_monthly: parseFloat(deductionData.lic_monthly || 0),
            gic_total: parseFloat(deductionData.gic_total || 0),
            gic_monthly: parseFloat(deductionData.gic_monthly || 0)
        },
        utilities: {
            electricity_total: parseFloat(deductionData.electricity_bill_total || 0),
            electricity_monthly: parseFloat(deductionData.electricity_bill_monthly || 0),
            water_total: parseFloat(deductionData.water_charges_total || 0),
            water_monthly: parseFloat(deductionData.water_charges_monthly || 0)
        },
        others: {
            recovery_total: parseFloat(deductionData.recovery_total || 0),
            recovery_monthly: parseFloat(deductionData.recovery_monthly || 0),
            income_tax_total: parseFloat(deductionData.income_tax_total || 0),
            income_tax_monthly: parseFloat(deductionData.income_tax_monthly || 0)
        }
    };
}

// Generate PDF payslip
async function generatePayslipPDF(payslipData, deductionData) {
    return new Promise((resolve, reject) => {
        try {
            // Create temporary file path
            const tempDir = path.join(__dirname, '../temp');
            if (!fs.existsSync(tempDir)) {
                fs.mkdirSync(tempDir, { recursive: true });
            }
            
            const pdfPath = path.join(tempDir, `payslip_${payslipData.id}_${Date.now()}.pdf`);
            
            // Create PDF document
            const doc = new PDFDocument({ margin: 40 });
            doc.pipe(fs.createWriteStream(pdfPath));
            
            // Header
            doc.fontSize(18).text('CANTONMENT BOARD AMBALA', { align: 'center' });
            doc.fontSize(16).text('PAYSLIP', { align: 'center' });
            doc.moveDown();
            
            // Employee details
            doc.fontSize(12);
            doc.text(`Employee ID: ${payslipData.emp_id}`);
            doc.text(`Name: ${payslipData.staff_name}`);
            doc.text(`Designation: ${payslipData.designation}`);
            doc.text(`Father's Name: ${payslipData.father_name || 'N/A'}`);
            doc.text(`Month/Year: ${payslipData.month}/${payslipData.year}`);
            doc.moveDown();
            
            // Earnings section
            doc.text('EARNINGS:', { underline: true });
            doc.text(`Basic Pay: ₹${parseFloat(payslipData.basic_pay).toFixed(2)}`);
            doc.text(`DA: ₹${parseFloat(payslipData.da).toFixed(2)}`);
            doc.text(`HRA: ₹${parseFloat(payslipData.hra).toFixed(2)}`);
            doc.text(`Special Pay: ₹${parseFloat(payslipData.special_pay || 0).toFixed(2)}`);
            doc.text(`Special Allowance: ₹${parseFloat(payslipData.special_allowance || 0).toFixed(2)}`);
            doc.text(`Other Allowance: ₹${parseFloat(payslipData.other_allowance || 0).toFixed(2)}`);
            doc.text(`GROSS SALARY: ₹${parseFloat(payslipData.gross_salary).toFixed(2)}`, { underline: true });
            doc.moveDown();
            
            // Deductions section
            doc.text('DEDUCTIONS:', { underline: true });
            doc.text(`Total Deductions: ₹${parseFloat(payslipData.total_deductions).toFixed(2)}`);
            doc.moveDown();
            
            // Net salary
            doc.fontSize(14);
            doc.text(`NET SALARY: ₹${parseFloat(payslipData.net_salary).toFixed(2)}`, { underline: true });
            doc.moveDown();
            
            // Attendance
            doc.fontSize(12);
            doc.text('ATTENDANCE:');
            doc.text(`Days Present: ${payslipData.days_present}`);
            doc.text(`Days Absent: ${payslipData.days_absent}`);
            doc.moveDown();
            
            // Bank details
            if (payslipData.bank_name && payslipData.account_number) {
                doc.text('BANK DETAILS:');
                doc.text(`Bank: ${payslipData.bank_name}`);
                doc.text(`Account: ${payslipData.account_number}`);
            }
            
            // Footer
            doc.fontSize(10);
            doc.text(`Generated on: ${new Date().toLocaleDateString()}`, { align: 'right' });
            
            doc.end();
            
            // Wait for PDF to be written
            doc.on('end', () => {
                resolve(pdfPath);
            });
            
        } catch (error) {
            reject(error);
        }
    });
}

module.exports = router;