const express = require('express');
const database = require('../config/database');
const router = express.Router();
const auth = require('../middleware/auth');

// =====================================================================
// ATTENDANCE RECORDS MANAGEMENT
// =====================================================================

// Get attendance records for a staff member for a specific month/year
router.get('/records/:staff_id/:year/:month', auth, async (req, res) => {
    try {
        const { staff_id, year, month } = req.params;

        // Get monthly attendance record
        const monthlyRecord = await database.query(`
            SELECT * FROM attendance_records 
            WHERE staff_id = ? AND year = ? AND month = ?
        `, [staff_id, year, month]);

        // Get daily attendance records if they exist
        const dailyRecords = await database.query(`
            SELECT * FROM daily_attendance 
            WHERE staff_id = ? 
            AND strftime('%Y', date) = ? 
            AND strftime('%m', date) = ?
            ORDER BY date
        `, [staff_id, year, month.toString().padStart(2, '0')]);

        // Get staff details
        const staff = await database.query(
            'SELECT * FROM admissions WHERE staff_id = ? OR id = ?',
            [staff_id, staff_id]
        );

        // Get leave applications for the month
        const leaveApplications = await database.query(`
            SELECT la.*, lt.leave_type_name, lt.color
            FROM leave_applications la
            JOIN leave_types lt ON la.leave_type_id = lt.id
            WHERE la.staff_id = ? AND la.status = 'approved'
            AND ((strftime('%Y', la.start_date) = ? AND strftime('%m', la.start_date) = ?)
                OR (strftime('%Y', la.end_date) = ? AND strftime('%m', la.end_date) = ?)
                OR (la.start_date <= ? AND la.end_date >= ?))
        `, [staff_id, year, month.toString().padStart(2, '0'), year, month.toString().padStart(2, '0'), 
            `${year}-${month.toString().padStart(2, '0')}-31`, `${year}-${month.toString().padStart(2, '0')}-01`]);

        res.json({
            success: true,
            staff: staff[0] || null,
            monthly_record: monthlyRecord[0] || null,
            daily_records: dailyRecords,
            leave_applications: leaveApplications,
            year: parseInt(year),
            month: parseInt(month)
        });

    } catch (error) {
        console.error('Get attendance records error:', error);
        res.status(500).json({ message: 'Failed to retrieve attendance records' });
    }
});

// Mark daily attendance
router.post('/mark', auth, async (req, res) => {
    try {
        const {
            staff_id,
            date,
            status, // 'present', 'absent', 'leave', 'holiday'
            check_in_time,
            check_out_time,
            total_hours,
            overtime_hours,
            remarks
        } = req.body;

        // Validation
        if (!staff_id || !date || !status) {
            return res.status(400).json({ 
                message: 'Missing required fields: staff_id, date, status' 
            });
        }

        // Check if staff exists
        const staff = await database.query(
            'SELECT * FROM admissions WHERE staff_id = ? OR id = ?', 
            [staff_id, staff_id]
        );
        if (staff.length === 0) {
            return res.status(404).json({ message: 'Staff member not found' });
        }

        // Check if attendance already marked for this date
        const existingRecord = await database.query(
            'SELECT id FROM daily_attendance WHERE staff_id = ? AND date = ?',
            [staff_id, date]
        );

        if (existingRecord.length > 0) {
            // Update existing record
            await database.run(`
                UPDATE daily_attendance SET 
                status = ?, check_in_time = ?, check_out_time = ?, 
                total_hours = ?, overtime_hours = ?, remarks = ?, 
                updated_at = CURRENT_TIMESTAMP
                WHERE staff_id = ? AND date = ?
            `, [status, check_in_time, check_out_time, total_hours || 0, 
                overtime_hours || 0, remarks, staff_id, date]);

            var action = 'update';
            var recordId = existingRecord[0].id;
        } else {
            // Insert new record
            const result = await database.run(`
                INSERT INTO daily_attendance (
                    staff_id, date, status, check_in_time, check_out_time,
                    total_hours, overtime_hours, remarks
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            `, [staff_id, date, status, check_in_time, check_out_time,
                total_hours || 0, overtime_hours || 0, remarks]);

            var action = 'create';
            var recordId = result.lastID;
        }

        // Update monthly attendance summary
        await updateMonthlyAttendanceSummary(staff_id, date);

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, action, 'attendance', recordId, `Marked attendance as ${status} for ${date}`, req.ip]
        );

        res.json({
            success: true,
            message: `Attendance ${action}d successfully`,
            record_id: recordId
        });

    } catch (error) {
        console.error('Mark attendance error:', error);
        res.status(500).json({ message: 'Failed to mark attendance' });
    }
});

// Update attendance record
router.put('/records/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;
        const {
            status,
            check_in_time,
            check_out_time,
            total_hours,
            overtime_hours,
            remarks
        } = req.body;

        // Check if record exists
        const record = await database.query('SELECT * FROM daily_attendance WHERE id = ?', [id]);
        if (record.length === 0) {
            return res.status(404).json({ message: 'Attendance record not found' });
        }

        // Update record
        const updateFields = [];
        const updateValues = [];

        if (status) {
            updateFields.push('status = ?');
            updateValues.push(status);
        }
        if (check_in_time !== undefined) {
            updateFields.push('check_in_time = ?');
            updateValues.push(check_in_time);
        }
        if (check_out_time !== undefined) {
            updateFields.push('check_out_time = ?');
            updateValues.push(check_out_time);
        }
        if (total_hours !== undefined) {
            updateFields.push('total_hours = ?');
            updateValues.push(total_hours);
        }
        if (overtime_hours !== undefined) {
            updateFields.push('overtime_hours = ?');
            updateValues.push(overtime_hours);
        }
        if (remarks !== undefined) {
            updateFields.push('remarks = ?');
            updateValues.push(remarks);
        }

        updateFields.push('updated_at = CURRENT_TIMESTAMP');
        updateValues.push(id);

        await database.run(
            `UPDATE daily_attendance SET ${updateFields.join(', ')} WHERE id = ?`,
            updateValues
        );

        // Update monthly summary
        await updateMonthlyAttendanceSummary(record[0].staff_id, record[0].date);

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, 'update', 'attendance', id, 'Updated attendance record', req.ip]
        );

        res.json({
            success: true,
            message: 'Attendance record updated successfully'
        });

    } catch (error) {
        console.error('Update attendance error:', error);
        res.status(500).json({ message: 'Failed to update attendance record' });
    }
});

// =====================================================================
// ATTENDANCE CALENDAR
// =====================================================================

// Get attendance calendar for all staff for a specific month/year
router.get('/calendar/:year/:month', auth, async (req, res) => {
    try {
        const { year, month } = req.params;
        const { staff_id } = req.query;

        // Base query for daily attendance
        let query = `
            SELECT da.*, a.name as staff_name, a.designation
            FROM daily_attendance da
            LEFT JOIN admissions a ON da.staff_id = a.staff_id
            WHERE strftime('%Y', da.date) = ? AND strftime('%m', da.date) = ?
        `;
        const params = [year, month.toString().padStart(2, '0')];

        if (staff_id) {
            query += ' AND da.staff_id = ?';
            params.push(staff_id);
        }

        query += ' ORDER BY da.date, a.name';

        const attendanceRecords = await database.query(query, params);

        // Get leave applications for the month
        let leaveQuery = `
            SELECT la.*, lt.leave_type_name, lt.color, a.name as staff_name
            FROM leave_applications la
            JOIN leave_types lt ON la.leave_type_id = lt.id
            LEFT JOIN admissions a ON la.staff_id = a.staff_id
            WHERE la.status = 'approved'
            AND ((strftime('%Y', la.start_date) = ? AND strftime('%m', la.start_date) = ?)
                OR (strftime('%Y', la.end_date) = ? AND strftime('%m', la.end_date) = ?)
                OR (la.start_date <= ? AND la.end_date >= ?))
        `;
        
        const monthStr = month.toString().padStart(2, '0');
        const firstDay = `${year}-${monthStr}-01`;
        const lastDay = `${year}-${monthStr}-${new Date(year, month, 0).getDate()}`;
        const leaveParams = [year, monthStr, year, monthStr, lastDay, firstDay];

        if (staff_id) {
            leaveQuery += ' AND la.staff_id = ?';
            leaveParams.push(staff_id);
        }

        const leaveApplications = await database.query(leaveQuery, leaveParams);

        // Get holidays for the month
        const holidays = await database.query(`
            SELECT * FROM holidays 
            WHERE strftime('%Y', date) = ? AND strftime('%m', date) = ?
        `, [year, month.toString().padStart(2, '0')]);

        res.json({
            success: true,
            year: parseInt(year),
            month: parseInt(month),
            attendance_records: attendanceRecords,
            leave_applications: leaveApplications,
            holidays: holidays
        });

    } catch (error) {
        console.error('Get attendance calendar error:', error);
        res.status(500).json({ message: 'Failed to retrieve attendance calendar' });
    }
});

// =====================================================================
// ATTENDANCE SUMMARY AND STATISTICS
// =====================================================================

// Get attendance summary for a staff member
router.get('/summary/:staff_id', auth, async (req, res) => {
    try {
        const { staff_id } = req.params;
        const { year, month } = req.query;
        const currentYear = year || new Date().getFullYear();
        const currentMonth = month || (new Date().getMonth() + 1);

        // Get staff details
        const staff = await database.query(
            'SELECT * FROM admissions WHERE staff_id = ? OR id = ?',
            [staff_id, staff_id]
        );

        if (staff.length === 0) {
            return res.status(404).json({ message: 'Staff member not found' });
        }

        // Get monthly summary
        const monthlySummary = await database.query(`
            SELECT * FROM attendance_records 
            WHERE staff_id = ? AND year = ? AND month = ?
        `, [staff_id, currentYear, currentMonth]);

        // Calculate detailed statistics
        const dailyStats = await database.query(`
            SELECT 
                status,
                COUNT(*) as count,
                COALESCE(SUM(total_hours), 0) as total_hours,
                COALESCE(SUM(overtime_hours), 0) as overtime_hours
            FROM daily_attendance
            WHERE staff_id = ? 
            AND strftime('%Y', date) = ? 
            AND strftime('%m', date) = ?
            GROUP BY status
        `, [staff_id, currentYear.toString(), currentMonth.toString().padStart(2, '0')]);

        // Get year-to-date statistics
        const ytdStats = await database.query(`
            SELECT 
                status,
                COUNT(*) as count,
                COALESCE(SUM(total_hours), 0) as total_hours,
                COALESCE(SUM(overtime_hours), 0) as overtime_hours
            FROM daily_attendance
            WHERE staff_id = ? AND strftime('%Y', date) = ?
            GROUP BY status
        `, [staff_id, currentYear.toString()]);

        // Calculate attendance percentage
        const workingDays = await database.query(`
            SELECT COUNT(*) as working_days
            FROM daily_attendance
            WHERE staff_id = ? 
            AND strftime('%Y', date) = ? 
            AND strftime('%m', date) = ?
            AND status != 'holiday'
        `, [staff_id, currentYear.toString(), currentMonth.toString().padStart(2, '0')]);

        const presentDays = dailyStats.find(s => s.status === 'present')?.count || 0;
        const totalWorkingDays = workingDays[0]?.working_days || 0;
        const attendancePercentage = totalWorkingDays > 0 ? ((presentDays / totalWorkingDays) * 100).toFixed(2) : 0;

        res.json({
            success: true,
            staff: staff[0],
            year: parseInt(currentYear),
            month: parseInt(currentMonth),
            monthly_summary: monthlySummary[0] || null,
            daily_statistics: dailyStats,
            ytd_statistics: ytdStats,
            attendance_percentage: parseFloat(attendancePercentage)
        });

    } catch (error) {
        console.error('Get attendance summary error:', error);
        res.status(500).json({ message: 'Failed to retrieve attendance summary' });
    }
});

// =====================================================================
// BULK OPERATIONS
// =====================================================================

// Bulk update attendance for multiple staff members
router.post('/bulk-update', auth, async (req, res) => {
    try {
        // Check if user has admin privileges
        const user = await database.query('SELECT role FROM users WHERE id = ?', [req.user.userId]);
        if (user.length === 0 || !['admin', 'super_admin', 'hr'].includes(user[0].role)) {
            return res.status(403).json({ message: 'Access denied. Admin privileges required.' });
        }

        const { date, staff_attendance } = req.body;

        if (!date || !staff_attendance || !Array.isArray(staff_attendance)) {
            return res.status(400).json({ 
                message: 'Missing required fields: date, staff_attendance (array)' 
            });
        }

        const results = [];
        const errors = [];

        // Process each staff member's attendance
        for (const attendance of staff_attendance) {
            try {
                const { staff_id, status, check_in_time, check_out_time, total_hours, overtime_hours, remarks } = attendance;

                if (!staff_id || !status) {
                    errors.push({ staff_id: staff_id || 'unknown', error: 'Missing staff_id or status' });
                    continue;
                }

                // Check if record exists
                const existing = await database.query(
                    'SELECT id FROM daily_attendance WHERE staff_id = ? AND date = ?',
                    [staff_id, date]
                );

                if (existing.length > 0) {
                    // Update existing record
                    await database.run(`
                        UPDATE daily_attendance SET 
                        status = ?, check_in_time = ?, check_out_time = ?, 
                        total_hours = ?, overtime_hours = ?, remarks = ?
                        WHERE staff_id = ? AND date = ?
                    `, [status, check_in_time, check_out_time, total_hours || 0, 
                        overtime_hours || 0, remarks, staff_id, date]);
                } else {
                    // Insert new record
                    await database.run(`
                        INSERT INTO daily_attendance (
                            staff_id, date, status, check_in_time, check_out_time,
                            total_hours, overtime_hours, remarks
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    `, [staff_id, date, status, check_in_time, check_out_time,
                        total_hours || 0, overtime_hours || 0, remarks]);
                }

                // Update monthly summary
                await updateMonthlyAttendanceSummary(staff_id, date);

                results.push({ staff_id, status: 'success' });

            } catch (error) {
                errors.push({ staff_id: attendance.staff_id || 'unknown', error: error.message });
            }
        }

        // Log the bulk operation
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, activity_description, ip_address) VALUES (?, ?, ?, ?, ?)',
            [req.user.userId, 'bulk_update', 'attendance', `Bulk updated attendance for ${date}`, req.ip]
        );

        res.json({
            success: true,
            message: 'Bulk attendance update completed',
            results: results,
            errors: errors,
            processed: staff_attendance.length,
            successful: results.length,
            failed: errors.length
        });

    } catch (error) {
        console.error('Bulk update attendance error:', error);
        res.status(500).json({ message: 'Failed to bulk update attendance' });
    }
});

// =====================================================================
// HELPER FUNCTIONS
// =====================================================================

// Update monthly attendance summary
async function updateMonthlyAttendanceSummary(staff_id, date) {
    try {
        const dateObj = new Date(date);
        const year = dateObj.getFullYear();
        const month = dateObj.getMonth() + 1;

        // Calculate monthly statistics
        const stats = await database.query(`
            SELECT 
                COUNT(CASE WHEN status = 'present' THEN 1 END) as days_present,
                COUNT(CASE WHEN status = 'absent' THEN 1 END) as days_absent,
                COUNT(CASE WHEN status = 'leave' THEN 1 END) as days_on_leave,
                COUNT(CASE WHEN status = 'holiday' THEN 1 END) as days_holiday,
                COALESCE(SUM(total_hours), 0) as total_hours,
                COALESCE(SUM(overtime_hours), 0) as total_overtime
            FROM daily_attendance
            WHERE staff_id = ? 
            AND strftime('%Y', date) = ? 
            AND strftime('%m', date) = ?
        `, [staff_id, year.toString(), month.toString().padStart(2, '0')]);

        const monthlyStats = stats[0];

        // Check if monthly record exists
        const existing = await database.query(
            'SELECT id FROM attendance_records WHERE staff_id = ? AND year = ? AND month = ?',
            [staff_id, year, month]
        );

        if (existing.length > 0) {
            // Update existing monthly record
            await database.run(`
                UPDATE attendance_records SET 
                days_present = ?, days_absent = ?, days_late = 0,
                overtime_hours = ?, updated_at = CURRENT_TIMESTAMP
                WHERE staff_id = ? AND year = ? AND month = ?
            `, [monthlyStats.days_present, monthlyStats.days_absent, 
                monthlyStats.total_overtime, staff_id, year, month]);
        } else {
            // Insert new monthly record
            await database.run(`
                INSERT INTO attendance_records (
                    staff_id, month, year, days_present, days_absent, 
                    days_late, overtime_hours, attendance_status
                ) VALUES (?, ?, ?, ?, ?, 0, ?, 'active')
            `, [staff_id, month, year, monthlyStats.days_present, 
                monthlyStats.days_absent, monthlyStats.total_overtime]);
        }

        return true;

    } catch (error) {
        console.error('Update monthly attendance summary error:', error);
        return false;
    }
}

module.exports = router;