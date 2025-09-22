const express = require('express');
const database = require('../config/database');
const router = express.Router();
const auth = require('../middleware/auth');

// =====================================================================
// DASHBOARD STATISTICS
// =====================================================================

// Get dashboard statistics for a user
router.get('/stats', auth, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { staff_id, role } = req.query;
        
        // Get user details and determine the appropriate staff_id
        let targetStaffId = staff_id;
        if (!targetStaffId) {
            // Try to find staff_id from user profile
            const userProfile = await database.query(`
                SELECT up.*, u.role
                FROM user_profiles up
                JOIN users u ON up.user_id = u.id
                WHERE up.user_id = ?
            `, [userId]);
            
            if (userProfile.length > 0 && userProfile[0].employee_id) {
                targetStaffId = userProfile[0].employee_id;
            }
        }

        let stats = {};

        if (targetStaffId) {
            // Get personal statistics for the staff member
            stats = await getPersonalStats(targetStaffId);
        } else {
            // Get general user statistics
            stats = await getGeneralUserStats(userId);
        }

        // Get user role to determine what additional stats to show
        const user = await database.query('SELECT role FROM users WHERE id = ?', [userId]);
        const userRole = user[0]?.role || 'user';

        if (['admin', 'super_admin', 'hr'].includes(userRole)) {
            // Add admin-specific statistics
            const adminStats = await getAdminStats();
            stats = { ...stats, ...adminStats, is_admin: true };
        }

        res.json({
            success: true,
            user_role: userRole,
            staff_id: targetStaffId,
            statistics: stats,
            last_updated: new Date().toISOString()
        });

    } catch (error) {
        console.error('Get dashboard stats error:', error);
        res.status(500).json({ message: 'Failed to retrieve dashboard statistics' });
    }
});

// =====================================================================
// NOTIFICATIONS MANAGEMENT
// =====================================================================

// Get notifications for a user
router.get('/notifications', auth, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { unread_only = 'false', limit = 20, offset = 0 } = req.query;

        let query = `
            SELECT n.*, u.username as created_by_username
            FROM notifications n
            LEFT JOIN users u ON n.created_by = u.id
            WHERE n.user_id = ? OR n.user_id IS NULL
        `;
        const params = [userId];

        if (unread_only === 'true') {
            query += ' AND n.is_read = 0';
        }

        query += ' ORDER BY n.is_read ASC, n.priority DESC, n.created_at DESC LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));

        const notifications = await database.query(query, params);

        // Get unread count
        const unreadCount = await database.query(
            'SELECT COUNT(*) as count FROM notifications WHERE (user_id = ? OR user_id IS NULL) AND is_read = 0',
            [userId]
        );

        res.json({
            success: true,
            notifications: notifications,
            unread_count: unreadCount[0]?.count || 0,
            total: notifications.length
        });

    } catch (error) {
        console.error('Get notifications error:', error);
        res.status(500).json({ message: 'Failed to retrieve notifications' });
    }
});

// Mark notification as read
router.put('/notifications/:id/read', auth, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;

        // Update notification
        const result = await database.run(
            'UPDATE notifications SET is_read = 1, read_at = CURRENT_TIMESTAMP WHERE id = ? AND (user_id = ? OR user_id IS NULL)',
            [id, userId]
        );

        if (result.changes === 0) {
            return res.status(404).json({ message: 'Notification not found' });
        }

        res.json({
            success: true,
            message: 'Notification marked as read'
        });

    } catch (error) {
        console.error('Mark notification read error:', error);
        res.status(500).json({ message: 'Failed to mark notification as read' });
    }
});

// Mark all notifications as read
router.put('/notifications/mark-all-read', auth, async (req, res) => {
    try {
        const userId = req.user.userId;

        await database.run(
            'UPDATE notifications SET is_read = 1, read_at = CURRENT_TIMESTAMP WHERE (user_id = ? OR user_id IS NULL) AND is_read = 0',
            [userId]
        );

        res.json({
            success: true,
            message: 'All notifications marked as read'
        });

    } catch (error) {
        console.error('Mark all notifications read error:', error);
        res.status(500).json({ message: 'Failed to mark all notifications as read' });
    }
});

// Create notification (for admins or system)
router.post('/notifications', auth, async (req, res) => {
    try {
        const {
            target_user_id,
            title,
            message,
            type = 'info', // 'info', 'warning', 'error', 'success'
            priority = 1,
            action_url
        } = req.body;

        if (!title || !message) {
            return res.status(400).json({ message: 'Title and message are required' });
        }

        // Create notification
        const result = await database.run(`
            INSERT INTO notifications (
                user_id, title, message, type, priority, action_url, created_by
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        `, [target_user_id, title, message, type, priority, action_url, req.user.userId]);

        res.status(201).json({
            success: true,
            message: 'Notification created successfully',
            notification_id: result.lastID
        });

    } catch (error) {
        console.error('Create notification error:', error);
        res.status(500).json({ message: 'Failed to create notification' });
    }
});

// =====================================================================
// RECENT ACTIVITY
// =====================================================================

// Get recent activity for a user
router.get('/recent-activity', auth, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { limit = 20, staff_id } = req.query;

        let query = `
            SELECT ua.*, u.username
            FROM user_activity ua
            LEFT JOIN users u ON ua.user_id = u.id
            WHERE ua.user_id = ?
        `;
        const params = [userId];

        // If staff_id is provided and user is admin, show system-wide activities for that staff
        const user = await database.query('SELECT role FROM users WHERE id = ?', [userId]);
        if (staff_id && ['admin', 'super_admin', 'hr'].includes(user[0]?.role)) {
            query = `
                SELECT ua.*, u.username, 'system_activity' as source_type
                FROM user_activity ua
                LEFT JOIN users u ON ua.user_id = u.id
                WHERE ua.activity_description LIKE ?
            `;
            params[0] = `%${staff_id}%`;
        }

        query += ' ORDER BY ua.timestamp DESC LIMIT ?';
        params.push(parseInt(limit));

        const activities = await database.query(query, params);

        res.json({
            success: true,
            activities: activities
        });

    } catch (error) {
        console.error('Get recent activity error:', error);
        res.status(500).json({ message: 'Failed to retrieve recent activity' });
    }
});

// =====================================================================
// QUICK ACTIONS AND SHORTCUTS
// =====================================================================

// Get quick actions available for the user
router.get('/quick-actions', auth, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        // Get user role and permissions
        const user = await database.query(`
            SELECT u.role, u.rights, up.employee_id
            FROM users u
            LEFT JOIN user_profiles up ON u.id = up.user_id
            WHERE u.id = ?
        `, [userId]);

        const userRole = user[0]?.role || 'user';
        const userRights = user[0]?.rights ? JSON.parse(user[0].rights) : {};
        const staffId = user[0]?.employee_id;

        const quickActions = [];

        // Common user actions
        if (staffId) {
            quickActions.push(
                {
                    id: 'apply_leave',
                    title: 'Apply for Leave',
                    description: 'Submit a new leave application',
                    icon: 'calendar',
                    url: '/leave/apply',
                    color: 'blue'
                },
                {
                    id: 'view_payslip',
                    title: 'View Payslip',
                    description: 'Access your salary information',
                    icon: 'document',
                    url: '/payslip/view',
                    color: 'green'
                },
                {
                    id: 'mark_attendance',
                    title: 'Mark Attendance',
                    description: 'Record your daily attendance',
                    icon: 'clock',
                    url: '/attendance/mark',
                    color: 'orange'
                },
                {
                    id: 'upload_document',
                    title: 'Upload Document',
                    description: 'Upload important documents',
                    icon: 'upload',
                    url: '/documents/upload',
                    color: 'purple'
                }
            );
        }

        // Admin-specific actions
        if (['admin', 'super_admin', 'hr'].includes(userRole)) {
            quickActions.push(
                {
                    id: 'manage_staff',
                    title: 'Manage Staff',
                    description: 'Add or edit staff members',
                    icon: 'users',
                    url: '/admin/staff',
                    color: 'red'
                },
                {
                    id: 'approve_leaves',
                    title: 'Approve Leaves',
                    description: 'Review pending leave applications',
                    icon: 'check-circle',
                    url: '/admin/leaves/pending',
                    color: 'teal'
                },
                {
                    id: 'generate_reports',
                    title: 'Generate Reports',
                    description: 'Create attendance and payroll reports',
                    icon: 'chart-bar',
                    url: '/admin/reports',
                    color: 'indigo'
                }
            );
        }

        res.json({
            success: true,
            user_role: userRole,
            quick_actions: quickActions
        });

    } catch (error) {
        console.error('Get quick actions error:', error);
        res.status(500).json({ message: 'Failed to retrieve quick actions' });
    }
});

// =====================================================================
// SYSTEM HEALTH AND STATUS
// =====================================================================

// Get system status (Admin only)
router.get('/system-status', auth, async (req, res) => {
    try {
        // Check if user is admin
        const user = await database.query('SELECT role FROM users WHERE id = ?', [req.user.userId]);
        if (user.length === 0 || !['admin', 'super_admin'].includes(user[0].role)) {
            return res.status(403).json({ message: 'Access denied. Admin privileges required.' });
        }

        const systemStatus = {
            database: 'healthy',
            storage: 'healthy',
            services: 'healthy',
            last_backup: null,
            uptime: process.uptime(),
            memory_usage: process.memoryUsage(),
            system_load: 'normal'
        };

        // Check database connectivity
        try {
            await database.query('SELECT 1');
            systemStatus.database = 'healthy';
        } catch (error) {
            systemStatus.database = 'error';
        }

        // Get recent errors
        const recentErrors = await database.query(`
            SELECT COUNT(*) as error_count
            FROM system_errors 
            WHERE timestamp >= datetime('now', '-24 hours')
        `);

        systemStatus.recent_errors = recentErrors[0]?.error_count || 0;

        // Get system metrics
        const metrics = await database.query(`
            SELECT 
                (SELECT COUNT(*) FROM users WHERE status = 'active') as active_users,
                (SELECT COUNT(*) FROM admissions) as total_staff,
                (SELECT COUNT(*) FROM leave_applications WHERE status = 'pending') as pending_leaves,
                (SELECT COUNT(*) FROM documents WHERE verification_status = 'pending') as pending_documents
        `);

        systemStatus.metrics = metrics[0];

        res.json({
            success: true,
            system_status: systemStatus,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Get system status error:', error);
        res.status(500).json({ message: 'Failed to retrieve system status' });
    }
});

// =====================================================================
// HELPER FUNCTIONS
// =====================================================================

// Get personal statistics for a staff member
async function getPersonalStats(staff_id) {
    try {
        const currentYear = new Date().getFullYear();
        const currentMonth = new Date().getMonth() + 1;

        // Leave statistics
        const leaveStats = await database.query(`
            SELECT 
                COUNT(*) as total_applications,
                COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_applications,
                COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_applications,
                COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_applications,
                COALESCE(SUM(CASE WHEN status = 'approved' THEN days ELSE 0 END), 0) as total_days_taken
            FROM leave_applications 
            WHERE staff_id = ? AND strftime('%Y', start_date) = ?
        `, [staff_id, currentYear.toString()]);

        // Attendance statistics
        const attendanceStats = await database.query(`
            SELECT 
                days_present, days_absent, overtime_hours,
                CASE WHEN (days_present + days_absent) > 0 
                     THEN (days_present * 100.0) / (days_present + days_absent) 
                     ELSE 0 END as attendance_percentage
            FROM attendance_records 
            WHERE staff_id = ? AND year = ? AND month = ?
        `, [staff_id, currentYear, currentMonth]);

        // Document statistics
        const documentStats = await database.query(`
            SELECT 
                COUNT(*) as total_documents,
                COUNT(CASE WHEN verification_status = 'verified' THEN 1 END) as verified_documents,
                COUNT(CASE WHEN verification_status = 'pending' THEN 1 END) as pending_documents
            FROM documents 
            WHERE staff_id = ? AND is_active = 1
        `, [staff_id]);

        // Recent payslip
        const recentPayslip = await database.query(`
            SELECT net_salary, month, year
            FROM payslips 
            WHERE staff_id = ? 
            ORDER BY year DESC, month DESC 
            LIMIT 1
        `, [staff_id]);

        return {
            leave: leaveStats[0] || {},
            attendance: attendanceStats[0] || {},
            documents: documentStats[0] || {},
            recent_payslip: recentPayslip[0] || null
        };

    } catch (error) {
        console.error('Get personal stats error:', error);
        return {};
    }
}

// Get general user statistics
async function getGeneralUserStats(user_id) {
    try {
        const stats = {
            login_count: 0,
            last_activity: null,
            notifications_count: 0,
            documents_uploaded: 0
        };

        // Get user login information
        const userInfo = await database.query(`
            SELECT login_count, last_login
            FROM users 
            WHERE id = ?
        `, [user_id]);

        if (userInfo.length > 0) {
            stats.login_count = userInfo[0].login_count || 0;
            stats.last_activity = userInfo[0].last_login;
        }

        // Get notifications count
        const notificationCount = await database.query(`
            SELECT COUNT(*) as count
            FROM notifications 
            WHERE user_id = ? AND is_read = 0
        `, [user_id]);

        stats.notifications_count = notificationCount[0]?.count || 0;

        return stats;

    } catch (error) {
        console.error('Get general user stats error:', error);
        return {};
    }
}

// Get admin-specific statistics
async function getAdminStats() {
    try {
        // System-wide statistics
        const systemStats = await database.query(`
            SELECT 
                (SELECT COUNT(*) FROM users WHERE status = 'active') as total_active_users,
                (SELECT COUNT(*) FROM admissions) as total_staff,
                (SELECT COUNT(*) FROM leave_applications WHERE status = 'pending') as pending_leave_applications,
                (SELECT COUNT(*) FROM documents WHERE verification_status = 'pending') as pending_document_verifications,
                (SELECT COUNT(*) FROM notifications WHERE is_read = 0) as unread_system_notifications
        `);

        // Recent activity counts
        const recentActivity = await database.query(`
            SELECT 
                COUNT(CASE WHEN timestamp >= datetime('now', '-24 hours') THEN 1 END) as activities_today,
                COUNT(CASE WHEN timestamp >= datetime('now', '-7 days') THEN 1 END) as activities_this_week
            FROM user_activity
        `);

        return {
            system: systemStats[0] || {},
            recent_activity: recentActivity[0] || {}
        };

    } catch (error) {
        console.error('Get admin stats error:', error);
        return {};
    }
}

module.exports = router;