const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const database = require('../config/database');
const router = express.Router();

// Helper function to log login attempts
async function logLoginAttempt(username, ip, userAgent, success, userId = null, failureReason = null) {
    try {
        await database.run(`
            INSERT INTO login_attempts (username, ip_address, user_agent, success, user_id, failure_reason)
            VALUES (?, ?, ?, ?, ?, ?)
        `, [username, ip, userAgent, success ? 1 : 0, userId, failureReason]);
    } catch (error) {
        console.error('Error logging login attempt:', error);
    }
}

// Helper function to create user session
async function createUserSession(userId, token, ip, userAgent) {
    try {
        const expiresAt = new Date();
        expiresAt.setHours(expiresAt.getHours() + 24); // 24 hour expiry

        await database.run(`
            INSERT INTO user_sessions (user_id, session_token, ip_address, user_agent, expires_at)
            VALUES (?, ?, ?, ?, ?)
        `, [userId, token, ip, userAgent, expiresAt.toISOString()]);
    } catch (error) {
        console.error('Error creating user session:', error);
    }
}

// Helper function to record login history
async function recordLoginHistory(userId, ip, userAgent) {
    try {
        await database.run(`
            INSERT INTO user_login_history (user_id, ip_address, user_agent, device_info)
            VALUES (?, ?, ?, ?)
        `, [userId, ip, userAgent, JSON.stringify({ userAgent, timestamp: new Date().toISOString() })]);
    } catch (error) {
        console.error('Error recording login history:', error);
    }
}

// Enhanced Login Route
router.post('/login', [
    body('username').trim().isLength({ min: 3 }).withMessage('Username must be at least 3 characters'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            await logLoginAttempt(req.body.username || 'unknown', req.ip, req.get('User-Agent'), false, null, 'validation_error');
            return res.status(400).json({ 
                message: 'Validation failed',
                errors: errors.array() 
            });
        }

        const { username, password } = req.body;
        const ip = req.ip;
        const userAgent = req.get('User-Agent');

        // Get user from database
        const users = await database.query(
            'SELECT * FROM users WHERE username = ? AND status = "active"', 
            [username]
        );
        const user = users[0];

        // Check if user exists
        if (!user) {
            await logLoginAttempt(username, ip, userAgent, false, null, 'invalid_username');
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Check if account is locked
        if (user.account_locked_until && new Date(user.account_locked_until) > new Date()) {
            await logLoginAttempt(username, ip, userAgent, false, user.id, 'account_locked');
            return res.status(423).json({ 
                message: 'Account is temporarily locked due to too many failed attempts. Try again later.' 
            });
        }

        // Verify password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            await logLoginAttempt(username, ip, userAgent, false, user.id, 'invalid_password');
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Generate JWT token
        const token = jwt.sign(
            { 
                userId: user.id, 
                username: user.username, 
                role: user.role 
            },
            process.env.JWT_SECRET || 'fallback_secret',
            { expiresIn: '24h' }
        );

        // Log successful login
        await logLoginAttempt(username, ip, userAgent, true, user.id);
        
        // Create user session
        await createUserSession(user.id, token, ip, userAgent);
        
        // Record login history
        await recordLoginHistory(user.id, ip, userAgent);

        // Update user activity
        await database.run(`
            INSERT INTO user_activity (user_id, activity_type, ip_address, user_agent, details)
            VALUES (?, 'login', ?, ?, ?)
        `, [user.id, ip, userAgent, JSON.stringify({ login_time: new Date().toISOString() })]);

        // Return successful response
        res.json({
            success: true,
            message: 'Login successful',
            token,
            user: {
                id: user.id,
                username: user.username,
                full_name: user.full_name,
                email: user.email,
                role: user.role,
                status: user.status,
                rights: user.rights ? JSON.parse(user.rights) : []
            }
        });

    } catch (error) {
        console.error('Login error:', error);
        await logLoginAttempt(req.body.username || 'unknown', req.ip, req.get('User-Agent'), false, null, 'server_error');
        res.status(500).json({ message: 'Server error during login' });
    }
});

// Enhanced Register Route
router.post('/register', [
    body('username').trim().isLength({ min: 3 }).withMessage('Username must be at least 3 characters'),
    body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
    body('full_name').trim().isLength({ min: 2 }).withMessage('Full name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('role').isIn(['admin', 'user', 'operator']).withMessage('Invalid role')
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ 
                message: 'Validation failed',
                errors: errors.array() 
            });
        }

        const { username, password, full_name, email, role } = req.body;

        // Check if username already exists
        const existingUsers = await database.query(
            'SELECT * FROM users WHERE username = ? OR email = ?', 
            [username, email]
        );
        
        if (existingUsers.length > 0) {
            const conflict = existingUsers[0].username === username ? 'username' : 'email';
            return res.status(400).json({ message: `This ${conflict} is already registered` });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 12);

        // Insert new user
        const result = await database.run(`
            INSERT INTO users (
                username, password, full_name, email, role, status, 
                email_verified, rights, password_changed_at
            ) VALUES (?, ?, ?, ?, ?, 'active', 0, ?, CURRENT_TIMESTAMP)
        `, [
            username, 
            hashedPassword, 
            full_name, 
            email, 
            role || 'user',
            JSON.stringify(['read']) // Default rights
        ]);

        // Log registration activity
        await database.run(`
            INSERT INTO user_activity (user_id, activity_type, ip_address, user_agent, details)
            VALUES (?, 'registration', ?, ?, ?)
        `, [
            result.id, 
            req.ip, 
            req.get('User-Agent'),
            JSON.stringify({ 
                username, 
                full_name, 
                email, 
                role,
                registration_time: new Date().toISOString() 
            })
        ]);

        res.status(201).json({ 
            success: true,
            message: 'User registered successfully',
            user_id: result.id 
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ message: 'Server error during registration' });
    }
});

// Logout Route
router.post('/logout', async (req, res) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        
        if (token) {
            // Decode token to get user info
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
            
            // Mark session as inactive
            await database.run(`
                UPDATE user_sessions 
                SET is_active = 0, logout_time = CURRENT_TIMESTAMP
                WHERE session_token = ? AND user_id = ?
            `, [token, decoded.userId]);

            // Log logout activity
            await database.run(`
                INSERT INTO user_activity (user_id, activity_type, ip_address, user_agent, details)
                VALUES (?, 'logout', ?, ?, ?)
            `, [
                decoded.userId, 
                req.ip, 
                req.get('User-Agent'),
                JSON.stringify({ logout_time: new Date().toISOString() })
            ]);
        }

        res.json({ 
            success: true,
            message: 'Logged out successfully' 
        });

    } catch (error) {
        console.error('Logout error:', error);
        res.json({ 
            success: true,
            message: 'Logged out successfully' 
        });
    }
});

// Verify Token Route
router.get('/verify', async (req, res) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        
        if (!token) {
            return res.status(401).json({ message: 'No token provided' });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
        
        // Check if session is still active
        const sessions = await database.query(
            'SELECT * FROM user_sessions WHERE session_token = ? AND user_id = ? AND is_active = 1',
            [token, decoded.userId]
        );

        if (sessions.length === 0) {
            return res.status(401).json({ message: 'Session expired or invalid' });
        }

        const session = sessions[0];
        
        // Check if session has expired
        if (new Date(session.expires_at) < new Date()) {
            await database.run(
                'UPDATE user_sessions SET is_active = 0, logout_time = CURRENT_TIMESTAMP WHERE id = ?',
                [session.id]
            );
            return res.status(401).json({ message: 'Session expired' });
        }

        // Update last activity
        await database.run(
            'UPDATE user_sessions SET last_activity = CURRENT_TIMESTAMP WHERE id = ?',
            [session.id]
        );

        // Get current user info
        const users = await database.query('SELECT * FROM users WHERE id = ?', [decoded.userId]);
        const user = users[0];

        if (!user || user.status !== 'active') {
            return res.status(401).json({ message: 'User account is not active' });
        }

        res.json({
            success: true,
            user: {
                id: user.id,
                username: user.username,
                full_name: user.full_name,
                email: user.email,
                role: user.role,
                status: user.status,
                rights: user.rights ? JSON.parse(user.rights) : []
            }
        });

    } catch (error) {
        console.error('Token verification error:', error);
        res.status(401).json({ message: 'Invalid token' });
    }
});

// Get Login Attempts (Admin only)
router.get('/login-attempts', async (req, res) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        
        if (!token) {
            return res.status(401).json({ message: 'Authentication required' });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
        const user = await database.query('SELECT role FROM users WHERE id = ?', [decoded.userId]);
        
        if (!user[0] || !['admin', 'super_admin'].includes(user[0].role)) {
            return res.status(403).json({ message: 'Admin access required' });
        }

        const { days = 7, limit = 100 } = req.query;

        const attempts = await database.query(`
            SELECT la.*, u.full_name, u.role
            FROM login_attempts la
            LEFT JOIN users u ON la.user_id = u.id
            WHERE la.attempt_time >= datetime('now', '-${parseInt(days)} days')
            ORDER BY la.attempt_time DESC
            LIMIT ?
        `, [parseInt(limit)]);

        res.json({
            success: true,
            login_attempts: attempts
        });

    } catch (error) {
        console.error('Get login attempts error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Active Sessions (Admin only)
router.get('/sessions', async (req, res) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        
        if (!token) {
            return res.status(401).json({ message: 'Authentication required' });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
        const user = await database.query('SELECT role FROM users WHERE id = ?', [decoded.userId]);
        
        if (!user[0] || !['admin', 'super_admin'].includes(user[0].role)) {
            return res.status(403).json({ message: 'Admin access required' });
        }

        const sessions = await database.query(`
            SELECT 
                us.id, us.user_id, us.ip_address, us.login_time, 
                us.last_activity, us.expires_at, us.is_active,
                u.username, u.full_name, u.role
            FROM user_sessions us
            JOIN users u ON us.user_id = u.id
            WHERE us.is_active = 1 AND us.expires_at > CURRENT_TIMESTAMP
            ORDER BY us.last_activity DESC
        `);

        res.json({
            success: true,
            active_sessions: sessions
        });

    } catch (error) {
        console.error('Get sessions error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router;