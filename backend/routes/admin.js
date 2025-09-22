const express = require('express');
const bcrypt = require('bcryptjs');
const database = require('../config/database');
const router = express.Router();
const auth = require('../middleware/auth');

// Middleware to check admin role
const adminAuth = (req, res, next) => {
    if (req.user.role !== 'admin' && req.user.role !== 'super_admin') {
        return res.status(403).json({ message: 'Admin access required' });
    }
    next();
};

// Admin Dashboard - Get summary statistics
router.get('/dashboard', auth, adminAuth, async (req, res) => {
    try {
        const stats = await database.query('SELECT * FROM admin_dashboard_summary');
        
        res.json({
            success: true,
            dashboard: stats[0] || {
                total_users: 0,
                active_users: 0,
                admin_users: 0,
                total_staff: 0,
                pending_leaves: 0,
                unresolved_errors: 0,
                unread_notifications: 0,
                active_sessions: 0
            }
        });

    } catch (error) {
        console.error('Admin dashboard error:', error);
        res.status(500).json({ message: 'Failed to load dashboard' });
    }
});

// User Management - Get all users
router.get('/users', auth, adminAuth, async (req, res) => {
    try {
        const { page = 1, limit = 50, role, status, search } = req.query;
        const offset = (page - 1) * limit;

        let query = `
            SELECT u.id, u.username, u.full_name, u.email, u.phone, u.role, u.status,
                   u.last_login, u.login_count, u.created_at,
                   up.department, up.designation
            FROM users u
            LEFT JOIN user_profiles up ON u.id = up.user_id
            WHERE 1=1
        `;
        const params = [];

        if (role) {
            query += ' AND u.role = ?';
            params.push(role);
        }

        if (status) {
            query += ' AND u.status = ?';
            params.push(status);
        }

        if (search) {
            query += ' AND (u.username LIKE ? OR u.full_name LIKE ? OR u.email LIKE ?)';
            params.push(`%${search}%`, `%${search}%`, `%${search}%`);
        }

        query += ' ORDER BY u.created_at DESC LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));

        const users = await database.query(query, params);

        // Get total count
        let countQuery = 'SELECT COUNT(*) as total FROM users WHERE 1=1';
        const countParams = [];

        if (role) {
            countQuery += ' AND role = ?';
            countParams.push(role);
        }

        if (status) {
            countQuery += ' AND status = ?';
            countParams.push(status);
        }

        if (search) {
            countQuery += ' AND (username LIKE ? OR full_name LIKE ? OR email LIKE ?)';
            countParams.push(`%${search}%`, `%${search}%`, `%${search}%`);
        }

        const countResult = await database.query(countQuery, countParams);

        res.json({
            success: true,
            users: users,
            total: countResult[0].total,
            page: parseInt(page),
            limit: parseInt(limit)
        });

    } catch (error) {
        console.error('Get users error:', error);
        res.status(500).json({ message: 'Failed to retrieve users' });
    }
});

// User Management - Create new user
router.post('/users', auth, adminAuth, async (req, res) => {
    try {
        const {
            username, full_name, email, phone, password, role = 'user',
            department, designation, rights = []
        } = req.body;

        // Validation
        if (!username || !password || !full_name) {
            return res.status(400).json({ message: 'Username, full name and password are required' });
        }

        // Check if username or email already exists
        const existingUser = await database.query(
            'SELECT id FROM users WHERE username = ? OR email = ?',
            [username, email]
        );

        if (existingUser.length > 0) {
            return res.status(400).json({ message: 'Username or email already exists' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 12);

        // Start transaction
        await database.run('BEGIN TRANSACTION');

        // Insert user
        const userResult = await database.run(`
            INSERT INTO users (
                username, full_name, email, phone, password, role, status, rights
            ) VALUES (?, ?, ?, ?, ?, ?, 'active', ?)
        `, [username, full_name, email, phone, hashedPassword, role, JSON.stringify(rights)]);

        // Insert user profile if additional info provided
        if (department || designation) {
            await database.run(`
                INSERT INTO user_profiles (user_id, department, designation)
                VALUES (?, ?, ?)
            `, [userResult.id, department, designation]);
        }

        // Log admin action
        await database.run(`
            INSERT INTO admin_actions (
                admin_user_id, action_type, target_entity, target_id, action_details, ip_address
            ) VALUES (?, 'user_create', 'user', ?, ?, ?)
        `, [
            req.user.userId, 
            userResult.id.toString(), 
            JSON.stringify({ username, full_name, email, role }),
            req.ip
        ]);

        await database.run('COMMIT');

        res.status(201).json({
            success: true,
            message: 'User created successfully',
            user_id: userResult.id
        });

    } catch (error) {
        await database.run('ROLLBACK');
        console.error('Create user error:', error);
        res.status(500).json({ message: 'Failed to create user' });
    }
});

// User Management - Update user
router.put('/users/:id', auth, adminAuth, async (req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body;

        // Don't allow updating password through this endpoint
        delete updates.password;

        const userFields = [];
        const userValues = [];
        const profileFields = [];
        const profileValues = [];

        // Separate user table fields from profile fields
        const userTableFields = ['username', 'full_name', 'email', 'phone', 'role', 'status', 'rights'];
        const profileTableFields = ['department', 'designation', 'employee_id', 'date_of_birth', 'gender', 'address', 'emergency_contact', 'bio'];

        for (const [key, value] of Object.entries(updates)) {
            if (userTableFields.includes(key)) {
                userFields.push(`${key} = ?`);
                userValues.push(key === 'rights' ? JSON.stringify(value) : value);
            } else if (profileTableFields.includes(key)) {
                profileFields.push(`${key} = ?`);
                profileValues.push(value);
            }
        }

        await database.run('BEGIN TRANSACTION');

        // Update user table
        if (userFields.length > 0) {
            userValues.push(id);
            await database.run(
                `UPDATE users SET ${userFields.join(', ')} WHERE id = ?`,
                userValues
            );
        }

        // Update user profile
        if (profileFields.length > 0) {
            profileValues.push(id);
            
            // Check if profile exists
            const existingProfile = await database.query(
                'SELECT id FROM user_profiles WHERE user_id = ?',
                [id]
            );

            if (existingProfile.length > 0) {
                await database.run(
                    `UPDATE user_profiles SET ${profileFields.join(', ')} WHERE user_id = ?`,
                    profileValues
                );
            } else {
                const insertFields = ['user_id', ...profileFields.map(f => f.split(' = ')[0])];
                const insertValues = [id, ...profileValues.slice(0, -1)];
                await database.run(
                    `INSERT INTO user_profiles (${insertFields.join(', ')}) VALUES (${insertFields.map(() => '?').join(', ')})`,
                    insertValues
                );
            }
        }

        // Log admin action
        await database.run(`
            INSERT INTO admin_actions (
                admin_user_id, action_type, target_entity, target_id, action_details, ip_address
            ) VALUES (?, 'user_update', 'user', ?, ?, ?)
        `, [req.user.userId, id, JSON.stringify(updates), req.ip]);

        await database.run('COMMIT');

        res.json({
            success: true,
            message: 'User updated successfully'
        });

    } catch (error) {
        await database.run('ROLLBACK');
        console.error('Update user error:', error);
        res.status(500).json({ message: 'Failed to update user' });
    }
});

// User Management - Delete user
router.delete('/users/:id', auth, adminAuth, async (req, res) => {
    try {
        const { id } = req.params;

        // Don't allow deleting own account
        if (parseInt(id) === req.user.userId) {
            return res.status(400).json({ message: 'Cannot delete your own account' });
        }

        // Get user details before deletion for logging
        const user = await database.query('SELECT username, full_name, email FROM users WHERE id = ?', [id]);
        
        if (user.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Delete user (cascade will handle related records)
        const result = await database.run('DELETE FROM users WHERE id = ?', [id]);

        if (result.changes === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Log admin action
        await database.run(`
            INSERT INTO admin_actions (
                admin_user_id, action_type, target_entity, target_id, action_details, ip_address
            ) VALUES (?, 'user_delete', 'user', ?, ?, ?)
        `, [req.user.userId, id, JSON.stringify(user[0]), req.ip]);

        res.json({
            success: true,
            message: 'User deleted successfully'
        });

    } catch (error) {
        console.error('Delete user error:', error);
        res.status(500).json({ message: 'Failed to delete user' });
    }
});

// System Logs - Get user activity logs
router.get('/logs', auth, adminAuth, async (req, res) => {
    try {
        const { page = 1, limit = 100, user_id, activity_type, days = 30 } = req.query;
        const offset = (page - 1) * limit;

        let query = `
            SELECT ua.*, u.username, u.full_name
            FROM user_activity ua
            LEFT JOIN users u ON ua.user_id = u.id
            WHERE ua.timestamp >= datetime('now', '-${parseInt(days)} days')
        `;
        const params = [];

        if (user_id) {
            query += ' AND ua.user_id = ?';
            params.push(user_id);
        }

        if (activity_type) {
            query += ' AND ua.activity_type = ?';
            params.push(activity_type);
        }

        query += ' ORDER BY ua.timestamp DESC LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));

        const logs = await database.query(query, params);

        res.json({
            success: true,
            logs: logs,
            page: parseInt(page),
            limit: parseInt(limit)
        });

    } catch (error) {
        console.error('Get logs error:', error);
        res.status(500).json({ message: 'Failed to retrieve logs' });
    }
});

// System Settings - Get all settings
router.get('/settings', auth, adminAuth, async (req, res) => {
    try {
        const { category } = req.query;

        let query = 'SELECT * FROM admin_settings WHERE 1=1';
        const params = [];

        if (category) {
            query += ' AND category = ?';
            params.push(category);
        }

        query += ' ORDER BY category, setting_key';

        const settings = await database.query(query, params);

        res.json({
            success: true,
            settings: settings
        });

    } catch (error) {
        console.error('Get settings error:', error);
        res.status(500).json({ message: 'Failed to retrieve settings' });
    }
});

// System Settings - Update setting
router.put('/settings/:id', auth, adminAuth, async (req, res) => {
    try {
        const { id } = req.params;
        const { setting_value } = req.body;

        await database.run(
            'UPDATE admin_settings SET setting_value = ? WHERE id = ?',
            [setting_value, id]
        );

        // Log admin action
        await database.run(`
            INSERT INTO admin_actions (
                admin_user_id, action_type, target_entity, target_id, action_details, ip_address
            ) VALUES (?, 'setting_update', 'system', ?, ?, ?)
        `, [req.user.userId, id, JSON.stringify({ new_value: setting_value }), req.ip]);

        res.json({
            success: true,
            message: 'Setting updated successfully'
        });

    } catch (error) {
        console.error('Update setting error:', error);
        res.status(500).json({ message: 'Failed to update setting' });
    }
});

// System Errors - Get error logs
router.get('/errors', auth, adminAuth, async (req, res) => {
    try {
        const { page = 1, limit = 50, resolved = false } = req.query;
        const offset = (page - 1) * limit;

        const errors = await database.query(`
            SELECT * FROM system_errors
            WHERE is_resolved = ?
            ORDER BY timestamp DESC
            LIMIT ? OFFSET ?
        `, [resolved === 'true' ? 1 : 0, parseInt(limit), parseInt(offset)]);

        res.json({
            success: true,
            errors: errors,
            page: parseInt(page),
            limit: parseInt(limit)
        });

    } catch (error) {
        console.error('Get errors error:', error);
        res.status(500).json({ message: 'Failed to retrieve errors' });
    }
});

// System Errors - Mark error as resolved
router.put('/errors/:id/resolve', auth, adminAuth, async (req, res) => {
    try {
        const { id } = req.params;

        await database.run(`
            UPDATE system_errors 
            SET is_resolved = 1, resolved_by = ?, resolved_at = CURRENT_TIMESTAMP
            WHERE id = ?
        `, [req.user.userId, id]);

        res.json({
            success: true,
            message: 'Error marked as resolved'
        });

    } catch (error) {
        console.error('Resolve error error:', error);
        res.status(500).json({ message: 'Failed to resolve error' });
    }
});

// Admin Notifications - Get notifications
router.get('/notifications', auth, adminAuth, async (req, res) => {
    try {
        const { unread_only = false } = req.query;

        let query = `
            SELECT * FROM admin_notifications
            WHERE (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
        `;

        if (unread_only === 'true') {
            query += ' AND is_read = 0';
        }

        query += ' ORDER BY priority DESC, created_at DESC LIMIT 50';

        const notifications = await database.query(query);

        res.json({
            success: true,
            notifications: notifications
        });

    } catch (error) {
        console.error('Get notifications error:', error);
        res.status(500).json({ message: 'Failed to retrieve notifications' });
    }
});

// Admin Notifications - Mark as read
router.put('/notifications/:id/read', auth, adminAuth, async (req, res) => {
    try {
        const { id } = req.params;

        await database.run(
            'UPDATE admin_notifications SET is_read = 1 WHERE id = ?',
            [id]
        );

        res.json({
            success: true,
            message: 'Notification marked as read'
        });

    } catch (error) {
        console.error('Mark notification read error:', error);
        res.status(500).json({ message: 'Failed to update notification' });
    }
});

// Recent Activity - Get recent admin and user activity
router.get('/recent-activity', auth, adminAuth, async (req, res) => {
    try {
        const { limit = 20 } = req.query;

        const activities = await database.query(`
            SELECT * FROM admin_recent_activity
            LIMIT ?
        `, [parseInt(limit)]);

        res.json({
            success: true,
            activities: activities
        });

    } catch (error) {
        console.error('Get recent activity error:', error);
        res.status(500).json({ message: 'Failed to retrieve recent activity' });
    }
});

// Admin Designations - Get all designations
router.get('/designations', auth, adminAuth, async (req, res) => {
    try {
        const designations = await database.query(
            'SELECT * FROM designations ORDER BY department, name'
        );
        
        res.json({
            success: true,
            designations: designations
        });

    } catch (error) {
        console.error('Get admin designations error:', error);
        res.status(500).json({ message: 'Failed to retrieve designations' });
    }
});

// Admin Designations - Create new designation
router.post('/designations', auth, adminAuth, async (req, res) => {
    try {
        const { name, department, description, pay_level_min, pay_level_max } = req.body;

        if (!name || !department) {
            return res.status(400).json({ message: 'Name and department are required' });
        }

        // Check if designation already exists
        const existingDesignation = await database.query(
            'SELECT id FROM designations WHERE name = ? AND department = ?',
            [name, department]
        );

        if (existingDesignation.length > 0) {
            return res.status(400).json({ message: 'Designation already exists in this department' });
        }

        const result = await database.run(`
            INSERT INTO designations (name, department, description, pay_level_min, pay_level_max, is_active)
            VALUES (?, ?, ?, ?, ?, 1)
        `, [name, department, description, pay_level_min, pay_level_max]);

        // Log admin action
        await database.run(`
            INSERT INTO admin_actions (
                admin_user_id, action_type, target_entity, target_id, action_details, ip_address
            ) VALUES (?, 'designation_create', 'designation', ?, ?, ?)
        `, [req.user.userId, result.id.toString(), JSON.stringify({ name, department }), req.ip]);

        res.status(201).json({
            success: true,
            message: 'Designation created successfully',
            designation_id: result.id
        });

    } catch (error) {
        console.error('Create admin designation error:', error);
        res.status(500).json({ message: 'Failed to create designation' });
    }
});

// Admin Designations - Update designation
router.put('/designations/:id', auth, adminAuth, async (req, res) => {
    try {
        const { id } = req.params;
        const { name, department, description, pay_level_min, pay_level_max, is_active } = req.body;

        // Check if designation exists
        const existingDesignation = await database.query(
            'SELECT * FROM designations WHERE id = ?',
            [id]
        );

        if (existingDesignation.length === 0) {
            return res.status(404).json({ message: 'Designation not found' });
        }

        await database.run(`
            UPDATE designations 
            SET name = ?, department = ?, description = ?, pay_level_min = ?, 
                pay_level_max = ?, is_active = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        `, [name, department, description, pay_level_min, pay_level_max, is_active, id]);

        // Log admin action
        await database.run(`
            INSERT INTO admin_actions (
                admin_user_id, action_type, target_entity, target_id, action_details, ip_address
            ) VALUES (?, 'designation_update', 'designation', ?, ?, ?)
        `, [req.user.userId, id, JSON.stringify({ name, department, old_data: existingDesignation[0] }), req.ip]);

        res.json({
            success: true,
            message: 'Designation updated successfully'
        });

    } catch (error) {
        console.error('Update admin designation error:', error);
        res.status(500).json({ message: 'Failed to update designation' });
    }
});

// Admin Designations - Delete designation
router.delete('/designations/:id', auth, adminAuth, async (req, res) => {
    try {
        const { id } = req.params;

        // Check if designation exists
        const existingDesignation = await database.query(
            'SELECT * FROM designations WHERE id = ?',
            [id]
        );

        if (existingDesignation.length === 0) {
            return res.status(404).json({ message: 'Designation not found' });
        }

        // Check if designation is being used by any staff
        const staffUsingDesignation = await database.query(
            'SELECT COUNT(*) as count FROM admissions WHERE designation = ?',
            [existingDesignation[0].name]
        );

        if (staffUsingDesignation[0].count > 0) {
            return res.status(400).json({ 
                message: `Cannot delete designation. It is currently assigned to ${staffUsingDesignation[0].count} staff member(s)` 
            });
        }

        // Also check users table if it has designation field
        try {
            const usersUsingDesignation = await database.query(
                'SELECT COUNT(*) as count FROM users WHERE designation = ?',
                [existingDesignation[0].name]
            );

            if (usersUsingDesignation[0].count > 0) {
                return res.status(400).json({ 
                    message: `Cannot delete designation. It is currently assigned to ${usersUsingDesignation[0].count} user(s)` 
                });
            }
        } catch (error) {
            // Ignore if users table doesn't have designation column
        }

        // Delete the designation
        const result = await database.run('DELETE FROM designations WHERE id = ?', [id]);

        if (result.changes === 0) {
            return res.status(404).json({ message: 'Designation not found' });
        }

        // Log admin action
        await database.run(`
            INSERT INTO admin_actions (
                admin_user_id, action_type, target_entity, target_id, action_details, ip_address
            ) VALUES (?, 'designation_delete', 'designation', ?, ?, ?)
        `, [req.user.userId, id, JSON.stringify(existingDesignation[0]), req.ip]);

        res.json({
            success: true,
            message: 'Designation deleted successfully'
        });

    } catch (error) {
        console.error('Delete admin designation error:', error);
        res.status(500).json({ message: 'Failed to delete designation' });
    }
});

module.exports = router;