const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const database = require('../config/database');
const router = express.Router();
const auth = require('../middleware/auth');

// Configure multer for leave document uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = 'uploads/leave_documents/';
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const timestamp = Date.now();
        const extension = path.extname(file.originalname);
        const staffId = req.body.staff_id || 'unknown';
        cb(null, `leave_${staffId}_${timestamp}${extension}`);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
    fileFilter: (req, file, cb) => {
        const allowedTypes = ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png', 
                            'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only PDF, JPEG, PNG, DOC, and DOCX are allowed.'));
        }
    }
});

// =====================================================================
// LEAVE APPLICATIONS MANAGEMENT
// =====================================================================

// Get all leave applications for a user
router.get('/applications', auth, async (req, res) => {
    try {
        const { staff_id, status, year } = req.query;
        
        let query = `
            SELECT la.*, lt.leave_type_name, lt.color, sp.name as staff_name
            FROM leave_applications la
            JOIN leave_types lt ON la.leave_type_id = lt.id
            LEFT JOIN staff_personal sp ON la.staff_id = sp.staff_id
            WHERE 1=1
        `;
        const params = [];

        if (staff_id) {
            query += ' AND la.staff_id = ?';
            params.push(staff_id);
        }

        if (status) {
            query += ' AND la.status = ?';
            params.push(status);
        }

        if (year) {
            query += ' AND strftime("%Y", la.start_date) = ?';
            params.push(year);
        }

        query += ' ORDER BY la.applied_at DESC';

        const applications = await database.query(query, params);

        res.json({
            success: true,
            applications: applications
        });

    } catch (error) {
        console.error('Get leave applications error:', error);
        res.status(500).json({ message: 'Failed to retrieve leave applications' });
    }
});

// Submit new leave application
router.post('/applications', auth, upload.single('document'), async (req, res) => {
    try {
        const {
            staff_id,
            leave_type_id,
            start_date,
            end_date,
            days,
            reason,
            half_day,
            half_day_period
        } = req.body;

        // Validation
        if (!staff_id || !leave_type_id || !start_date || !end_date || !days || !reason) {
            return res.status(400).json({ 
                message: 'Missing required fields: staff_id, leave_type_id, start_date, end_date, days, reason' 
            });
        }

        // Check if staff exists
        const staff = await database.query('SELECT * FROM admissions WHERE staff_id = ? OR id = ?', [staff_id, staff_id]);
        if (staff.length === 0) {
            return res.status(404).json({ message: 'Staff member not found' });
        }

        // Check leave balance
        const leaveBalance = await getLeaveBalance(staff_id, leave_type_id);
        if (leaveBalance.available < parseInt(days)) {
            return res.status(400).json({ 
                message: `Insufficient leave balance. Available: ${leaveBalance.available} days, Requested: ${days} days` 
            });
        }

        // Handle document upload
        let document_path = null;
        if (req.file) {
            document_path = `/uploads/leave_documents/${req.file.filename}`;
        }

        // Insert leave application
        const result = await database.run(`
            INSERT INTO leave_applications (
                staff_id, leave_type_id, start_date, end_date, days, reason, 
                document_path, half_day, half_day_period, status, applied_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', CURRENT_TIMESTAMP)
        `, [staff_id, leave_type_id, start_date, end_date, days, reason, 
            document_path, half_day || false, half_day_period, ]);

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, 'create', 'leave_application', result.lastID, `Applied for ${days} days leave`, req.ip]
        );

        // Get the complete application data
        const newApplication = await database.query(`
            SELECT la.*, lt.leave_type_name, lt.color 
            FROM leave_applications la
            JOIN leave_types lt ON la.leave_type_id = lt.id
            WHERE la.id = ?
        `, [result.lastID]);

        res.status(201).json({
            success: true,
            message: 'Leave application submitted successfully',
            application: newApplication[0]
        });

    } catch (error) {
        console.error('Submit leave application error:', error);
        res.status(500).json({ message: 'Failed to submit leave application' });
    }
});

// Update leave application (for staff to edit pending applications)
router.put('/applications/:id', auth, upload.single('document'), async (req, res) => {
    try {
        const { id } = req.params;
        const { start_date, end_date, days, reason, half_day, half_day_period } = req.body;

        // Check if application exists and is pending
        const application = await database.query(
            'SELECT * FROM leave_applications WHERE id = ? AND status = ?',
            [id, 'pending']
        );

        if (application.length === 0) {
            return res.status(404).json({ message: 'Leave application not found or cannot be edited' });
        }

        // Check leave balance for the new duration
        if (days) {
            const leaveBalance = await getLeaveBalance(application[0].staff_id, application[0].leave_type_id);
            const currentlyUsed = parseInt(application[0].days);
            const newRequested = parseInt(days);
            const netChange = newRequested - currentlyUsed;
            
            if (netChange > 0 && leaveBalance.available < netChange) {
                return res.status(400).json({ 
                    message: `Insufficient leave balance for the increase. Additional days needed: ${netChange}` 
                });
            }
        }

        // Handle document upload
        let document_path = application[0].document_path;
        if (req.file) {
            document_path = `/uploads/leave_documents/${req.file.filename}`;
        }

        // Update fields
        const updateFields = [];
        const updateValues = [];

        if (start_date) {
            updateFields.push('start_date = ?');
            updateValues.push(start_date);
        }
        if (end_date) {
            updateFields.push('end_date = ?');
            updateValues.push(end_date);
        }
        if (days) {
            updateFields.push('days = ?');
            updateValues.push(days);
        }
        if (reason) {
            updateFields.push('reason = ?');
            updateValues.push(reason);
        }
        if (half_day !== undefined) {
            updateFields.push('half_day = ?');
            updateValues.push(half_day);
        }
        if (half_day_period) {
            updateFields.push('half_day_period = ?');
            updateValues.push(half_day_period);
        }
        if (document_path !== application[0].document_path) {
            updateFields.push('document_path = ?');
            updateValues.push(document_path);
        }

        updateFields.push('updated_at = CURRENT_TIMESTAMP');
        updateValues.push(id);

        await database.run(
            `UPDATE leave_applications SET ${updateFields.join(', ')} WHERE id = ?`,
            updateValues
        );

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, 'update', 'leave_application', id, 'Updated leave application', req.ip]
        );

        res.json({
            success: true,
            message: 'Leave application updated successfully'
        });

    } catch (error) {
        console.error('Update leave application error:', error);
        res.status(500).json({ message: 'Failed to update leave application' });
    }
});

// Cancel leave application
router.delete('/applications/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;

        // Check if application exists and can be cancelled
        const application = await database.query(
            'SELECT * FROM leave_applications WHERE id = ? AND status IN (?, ?)',
            [id, 'pending', 'approved']
        );

        if (application.length === 0) {
            return res.status(404).json({ message: 'Leave application not found or cannot be cancelled' });
        }

        // Update status to cancelled
        await database.run(
            'UPDATE leave_applications SET status = ?, cancelled_at = CURRENT_TIMESTAMP WHERE id = ?',
            ['cancelled', id]
        );

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, 'cancel', 'leave_application', id, 'Cancelled leave application', req.ip]
        );

        res.json({
            success: true,
            message: 'Leave application cancelled successfully'
        });

    } catch (error) {
        console.error('Cancel leave application error:', error);
        res.status(500).json({ message: 'Failed to cancel leave application' });
    }
});

// =====================================================================
// LEAVE TYPES MANAGEMENT
// =====================================================================

// Get all leave types
router.get('/types', auth, async (req, res) => {
    try {
        const leaveTypes = await database.query(
            'SELECT * FROM leave_types WHERE is_active = 1 ORDER BY leave_type_name'
        );

        res.json({
            success: true,
            leave_types: leaveTypes
        });

    } catch (error) {
        console.error('Get leave types error:', error);
        res.status(500).json({ message: 'Failed to retrieve leave types' });
    }
});

// =====================================================================
// LEAVE BALANCE MANAGEMENT
// =====================================================================

// Get leave balance for a staff member
router.get('/balance/:staff_id', auth, async (req, res) => {
    try {
        const { staff_id } = req.params;
        const { year } = req.query;
        const currentYear = year || new Date().getFullYear();

        // Get all leave types
        const leaveTypes = await database.query(
            'SELECT * FROM leave_types WHERE is_active = 1 ORDER BY leave_type_name'
        );

        const balances = {};

        for (const leaveType of leaveTypes) {
            const balance = await getLeaveBalance(staff_id, leaveType.id, currentYear);
            balances[leaveType.id] = {
                leave_type_name: leaveType.leave_type_name,
                color: leaveType.color,
                ...balance
            };
        }

        res.json({
            success: true,
            staff_id: staff_id,
            year: currentYear,
            balances: balances
        });

    } catch (error) {
        console.error('Get leave balance error:', error);
        res.status(500).json({ message: 'Failed to retrieve leave balance' });
    }
});

// =====================================================================
// LEAVE CALENDAR
// =====================================================================

// Get leave calendar data for a specific month/year
router.get('/calendar/:year/:month', auth, async (req, res) => {
    try {
        const { year, month } = req.params;
        const { staff_id } = req.query;

        let query = `
            SELECT la.*, lt.leave_type_name, lt.color, sp.name as staff_name
            FROM leave_applications la
            JOIN leave_types lt ON la.leave_type_id = lt.id
            LEFT JOIN staff_personal sp ON la.staff_id = sp.staff_id
            WHERE la.status = 'approved'
            AND ((strftime('%Y', la.start_date) = ? AND strftime('%m', la.start_date) = ?)
                OR (strftime('%Y', la.end_date) = ? AND strftime('%m', la.end_date) = ?)
                OR (la.start_date <= ? AND la.end_date >= ?))
        `;
        
        const monthStr = month.toString().padStart(2, '0');
        const firstDay = `${year}-${monthStr}-01`;
        const lastDay = `${year}-${monthStr}-${new Date(year, month, 0).getDate()}`;
        
        const params = [year, monthStr, year, monthStr, lastDay, firstDay];

        if (staff_id) {
            query += ' AND la.staff_id = ?';
            params.push(staff_id);
        }

        query += ' ORDER BY la.start_date';

        const leaves = await database.query(query, params);

        res.json({
            success: true,
            year: parseInt(year),
            month: parseInt(month),
            leaves: leaves
        });

    } catch (error) {
        console.error('Get leave calendar error:', error);
        res.status(500).json({ message: 'Failed to retrieve leave calendar' });
    }
});

// =====================================================================
// ADMIN FUNCTIONS (Leave Approval)
// =====================================================================

// Approve/Reject leave application (Admin only)
router.put('/applications/:id/status', auth, async (req, res) => {
    try {
        // Check if user is admin
        const user = await database.query('SELECT role FROM users WHERE id = ?', [req.user.userId]);
        if (user.length === 0 || !['admin', 'super_admin', 'hr'].includes(user[0].role)) {
            return res.status(403).json({ message: 'Access denied. Admin privileges required.' });
        }

        const { id } = req.params;
        const { status, rejection_reason } = req.body;

        if (!['approved', 'rejected'].includes(status)) {
            return res.status(400).json({ message: 'Invalid status. Must be approved or rejected.' });
        }

        if (status === 'rejected' && !rejection_reason) {
            return res.status(400).json({ message: 'Rejection reason is required when rejecting application.' });
        }

        // Get application details
        const application = await database.query('SELECT * FROM leave_applications WHERE id = ?', [id]);
        if (application.length === 0) {
            return res.status(404).json({ message: 'Leave application not found' });
        }

        // Update application status
        await database.run(
            `UPDATE leave_applications SET 
             status = ?, approved_by = ?, approved_at = CURRENT_TIMESTAMP, 
             rejection_reason = ? WHERE id = ?`,
            [status, req.user.userId, rejection_reason, id]
        );

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, status, 'leave_application', id, `${status} leave application`, req.ip]
        );

        res.json({
            success: true,
            message: `Leave application ${status} successfully`
        });

    } catch (error) {
        console.error('Update leave status error:', error);
        res.status(500).json({ message: 'Failed to update leave status' });
    }
});

// =====================================================================
// HELPER FUNCTIONS
// =====================================================================

// Calculate leave balance for a staff member and leave type
async function getLeaveBalance(staff_id, leave_type_id, year = null) {
    try {
        const currentYear = year || new Date().getFullYear();
        
        // Get leave type details
        const leaveType = await database.query('SELECT * FROM leave_types WHERE id = ?', [leave_type_id]);
        if (leaveType.length === 0) {
            return { error: 'Leave type not found' };
        }

        const type = leaveType[0];
        let entitled = type.max_days_per_year || 0;

        // Get staff joining date for prorated calculation
        const staff = await database.query('SELECT date_of_joining FROM admissions WHERE staff_id = ? OR id = ?', [staff_id, staff_id]);
        const joiningYear = staff.length > 0 ? new Date(staff[0].date_of_joining).getFullYear() : currentYear;

        // Prorate entitlement for first year
        if (currentYear === joiningYear && staff.length > 0) {
            const joiningDate = new Date(staff[0].date_of_joining);
            const yearStart = new Date(currentYear, 0, 1);
            const monthsWorked = Math.max(0, 12 - joiningDate.getMonth() + (joiningDate.getDate() > 15 ? 0 : 1));
            entitled = Math.floor((entitled * monthsWorked) / 12);
        }

        // Calculate used leaves for the year
        const usedLeaves = await database.query(`
            SELECT COALESCE(SUM(days), 0) as used_days
            FROM leave_applications 
            WHERE staff_id = ? AND leave_type_id = ? 
            AND status = 'approved'
            AND strftime('%Y', start_date) = ?
        `, [staff_id, leave_type_id, currentYear.toString()]);

        const used = usedLeaves[0]?.used_days || 0;

        // Calculate carried forward (if applicable)
        let carried_forward = 0;
        if (type.carry_forward_allowed && currentYear > joiningYear) {
            // This is simplified - you might want more complex carryover logic
            const previousYearBalance = await database.query(`
                SELECT COALESCE(SUM(days), 0) as used_days
                FROM leave_applications 
                WHERE staff_id = ? AND leave_type_id = ? 
                AND status = 'approved'
                AND strftime('%Y', start_date) = ?
            `, [staff_id, leave_type_id, (currentYear - 1).toString()]);
            
            const previousUsed = previousYearBalance[0]?.used_days || 0;
            const previousEntitled = type.max_days_per_year;
            const previousRemaining = Math.max(0, previousEntitled - previousUsed);
            
            // Allow carrying forward up to 30 days (or whatever your policy is)
            carried_forward = Math.min(previousRemaining, 30);
        }

        const total_entitled = entitled + carried_forward;
        const available = Math.max(0, total_entitled - used);

        return {
            entitled,
            carried_forward,
            total_entitled,
            used,
            available,
            leave_type_name: type.leave_type_name
        };

    } catch (error) {
        console.error('Calculate leave balance error:', error);
        return { error: 'Failed to calculate leave balance' };
    }
}

module.exports = router;