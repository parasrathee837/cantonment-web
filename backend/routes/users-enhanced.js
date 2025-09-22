const express = require('express');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
const database = require('../config/database');
const router = express.Router();
const auth = require('../middleware/auth');

// Configure multer for profile photo uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/profiles/');
    },
    filename: (req, file, cb) => {
        const timestamp = Date.now();
        const extension = path.extname(file.originalname);
        cb(null, `profile_${req.user.userId}_${timestamp}${extension}`);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 2 * 1024 * 1024 }, // 2MB limit for profile photos
    fileFilter: (req, file, cb) => {
        const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only JPEG, PNG and GIF are allowed.'));
        }
    }
});

// Get user profile (complete information)
router.get('/profile', auth, async (req, res) => {
    try {
        const user = await database.query(
            'SELECT * FROM user_complete_profile WHERE id = ?',
            [req.user.userId]
        );

        if (user.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Remove password from response
        const { password, ...userProfile } = user[0];
        
        res.json({
            success: true,
            user: userProfile
        });

    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({ message: 'Failed to retrieve profile' });
    }
});

// Update user profile
router.put('/profile', auth, async (req, res) => {
    try {
        const userId = req.user.userId;
        const {
            full_name,
            email,
            phone,
            department,
            designation,
            employee_id,
            date_of_birth,
            gender,
            address,
            emergency_contact,
            bio,
            preferences
        } = req.body;

        // Start transaction
        await database.run('BEGIN TRANSACTION');

        // Update main user information
        if (full_name || email || phone) {
            const userFields = [];
            const userValues = [];

            if (full_name) {
                userFields.push('full_name = ?');
                userValues.push(full_name);
            }
            if (email) {
                // Check if email is already taken by another user
                const emailCheck = await database.query(
                    'SELECT id FROM users WHERE email = ? AND id != ?',
                    [email, userId]
                );
                if (emailCheck.length > 0) {
                    await database.run('ROLLBACK');
                    return res.status(400).json({ message: 'Email already in use by another user' });
                }
                userFields.push('email = ?');
                userValues.push(email);
            }
            if (phone) {
                userFields.push('phone = ?');
                userValues.push(phone);
            }

            if (userFields.length > 0) {
                userValues.push(userId);
                await database.run(
                    `UPDATE users SET ${userFields.join(', ')} WHERE id = ?`,
                    userValues
                );
            }
        }

        // Update extended profile information
        if (department || designation || employee_id || date_of_birth || gender || address || emergency_contact || bio || preferences) {
            const profileFields = [];
            const profileValues = [];

            if (department) {
                profileFields.push('department = ?');
                profileValues.push(department);
            }
            if (designation) {
                profileFields.push('designation = ?');
                profileValues.push(designation);
            }
            if (employee_id) {
                profileFields.push('employee_id = ?');
                profileValues.push(employee_id);
            }
            if (date_of_birth) {
                profileFields.push('date_of_birth = ?');
                profileValues.push(date_of_birth);
            }
            if (gender) {
                profileFields.push('gender = ?');
                profileValues.push(gender);
            }
            if (address) {
                profileFields.push('address = ?');
                profileValues.push(address);
            }
            if (emergency_contact) {
                profileFields.push('emergency_contact = ?');
                profileValues.push(emergency_contact);
            }
            if (bio) {
                profileFields.push('bio = ?');
                profileValues.push(bio);
            }
            if (preferences) {
                profileFields.push('preferences = ?');
                profileValues.push(JSON.stringify(preferences));
            }

            if (profileFields.length > 0) {
                profileValues.push(userId);
                
                // Check if profile exists
                const existingProfile = await database.query(
                    'SELECT id FROM user_profiles WHERE user_id = ?',
                    [userId]
                );

                if (existingProfile.length > 0) {
                    // Update existing profile
                    await database.run(
                        `UPDATE user_profiles SET ${profileFields.join(', ')} WHERE user_id = ?`,
                        profileValues
                    );
                } else {
                    // Create new profile
                    const insertFields = ['user_id', ...profileFields.map(f => f.split(' = ')[0])];
                    const insertValues = [userId, ...profileValues.slice(0, -1)];
                    await database.run(
                        `INSERT INTO user_profiles (${insertFields.join(', ')}) VALUES (${insertFields.map(() => '?').join(', ')})`,
                        insertValues
                    );
                }
            }
        }

        // Commit transaction
        await database.run('COMMIT');

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, ip_address, details) VALUES (?, ?, ?, ?)',
            [userId, 'profile_update', req.ip, JSON.stringify({ updated_fields: Object.keys(req.body) })]
        );

        // Get updated profile
        const updatedUser = await database.query(
            'SELECT * FROM user_complete_profile WHERE id = ?',
            [userId]
        );

        const { password, ...userProfile } = updatedUser[0];

        res.json({
            success: true,
            message: 'Profile updated successfully',
            user: userProfile
        });

    } catch (error) {
        await database.run('ROLLBACK');
        console.error('Update profile error:', error);
        res.status(500).json({ message: 'Failed to update profile', error: error.message });
    }
});

// Change password
router.put('/change-password', auth, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({ message: 'Current password and new password are required' });
        }

        if (newPassword.length < 8) {
            return res.status(400).json({ message: 'New password must be at least 8 characters long' });
        }

        // Get current user password
        const user = await database.query('SELECT password FROM users WHERE id = ?', [userId]);
        
        if (user.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Verify current password
        const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user[0].password);
        if (!isCurrentPasswordValid) {
            return res.status(400).json({ message: 'Current password is incorrect' });
        }

        // Check if new password was used recently (last 5 passwords)
        const recentPasswords = await database.query(
            'SELECT password_hash FROM user_password_history WHERE user_id = ? ORDER BY created_at DESC LIMIT 5',
            [userId]
        );

        for (const oldPassword of recentPasswords) {
            const isOldPassword = await bcrypt.compare(newPassword, oldPassword.password_hash);
            if (isOldPassword) {
                return res.status(400).json({ message: 'Cannot use a recently used password' });
            }
        }

        // Hash new password
        const saltRounds = 12;
        const hashedNewPassword = await bcrypt.hash(newPassword, saltRounds);

        // Update password
        await database.run('UPDATE users SET password = ? WHERE id = ?', [hashedNewPassword, userId]);

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, ip_address, user_agent) VALUES (?, ?, ?, ?)',
            [userId, 'password_change', req.ip, req.get('User-Agent')]
        );

        res.json({
            success: true,
            message: 'Password changed successfully'
        });

    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({ message: 'Failed to change password' });
    }
});

// Upload profile photo
router.post('/profile-photo', auth, upload.single('photo'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No photo uploaded' });
        }

        const photoPath = `/uploads/profiles/${req.file.filename}`;

        // Update user's profile photo path
        await database.run(
            'UPDATE users SET profile_photo = ? WHERE id = ?',
            [photoPath, req.user.userId]
        );

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, ip_address, details) VALUES (?, ?, ?, ?)',
            [req.user.userId, 'profile_photo_update', req.ip, JSON.stringify({ filename: req.file.filename })]
        );

        res.json({
            success: true,
            message: 'Profile photo updated successfully',
            photo_url: photoPath
        });

    } catch (error) {
        console.error('Profile photo upload error:', error);
        res.status(500).json({ message: 'Failed to upload profile photo' });
    }
});

// Get user activity log
router.get('/activity', auth, async (req, res) => {
    try {
        const { limit = 50, offset = 0 } = req.query;

        const activities = await database.query(
            `SELECT activity_type, ip_address, details, timestamp 
             FROM user_activity 
             WHERE user_id = ? 
             ORDER BY timestamp DESC 
             LIMIT ? OFFSET ?`,
            [req.user.userId, parseInt(limit), parseInt(offset)]
        );

        res.json({
            success: true,
            activities: activities
        });

    } catch (error) {
        console.error('Get activity error:', error);
        res.status(500).json({ message: 'Failed to retrieve activity log' });
    }
});

// Get all users (admin only)
router.get('/all', auth, async (req, res) => {
    try {
        // Check if user is admin
        const currentUser = await database.query('SELECT role FROM users WHERE id = ?', [req.user.userId]);
        if (currentUser.length === 0 || currentUser[0].role !== 'admin') {
            return res.status(403).json({ message: 'Access denied. Admin role required.' });
        }

        const users = await database.query(
            'SELECT id, username, full_name, email, phone, role, status, last_login, created_at FROM users ORDER BY created_at DESC'
        );

        res.json({
            success: true,
            users: users
        });

    } catch (error) {
        console.error('Get all users error:', error);
        res.status(500).json({ message: 'Failed to retrieve users' });
    }
});

// Update user status (admin only)
router.put('/:userId/status', auth, async (req, res) => {
    try {
        // Check if user is admin
        const currentUser = await database.query('SELECT role FROM users WHERE id = ?', [req.user.userId]);
        if (currentUser.length === 0 || currentUser[0].role !== 'admin') {
            return res.status(403).json({ message: 'Access denied. Admin role required.' });
        }

        const { status } = req.body;
        const { userId } = req.params;

        if (!['active', 'inactive', 'suspended'].includes(status)) {
            return res.status(400).json({ message: 'Invalid status. Must be active, inactive, or suspended.' });
        }

        await database.run('UPDATE users SET status = ? WHERE id = ?', [status, userId]);

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, ip_address, details) VALUES (?, ?, ?, ?)',
            [req.user.userId, 'user_status_change', req.ip, JSON.stringify({ target_user_id: userId, new_status: status })]
        );

        res.json({
            success: true,
            message: `User status updated to ${status}`
        });

    } catch (error) {
        console.error('Update user status error:', error);
        res.status(500).json({ message: 'Failed to update user status' });
    }
});

// Delete user (admin only)
router.delete('/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;
        
        // Check if user is admin
        const currentUser = await database.query('SELECT role FROM users WHERE id = ?', [req.user.userId]);
        if (currentUser.length === 0 || currentUser[0].role !== 'admin') {
            return res.status(403).json({ message: 'Access denied. Admin role required.' });
        }

        // Check if user exists
        const userToDelete = await database.query('SELECT username FROM users WHERE id = ?', [id]);
        if (userToDelete.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Prevent admin from deleting themselves
        if (parseInt(id) === req.user.userId) {
            return res.status(400).json({ message: 'Cannot delete your own account' });
        }

        // Delete the user
        const result = await database.run('DELETE FROM users WHERE id = ?', [id]);
        
        if (result.changes === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, ip_address, details) VALUES (?, ?, ?, ?)',
            [req.user.userId, 'user_deleted', req.ip, JSON.stringify({ deleted_user_id: id, deleted_username: userToDelete[0].username })]
        );

        res.json({
            success: true,
            message: 'User deleted successfully'
        });

    } catch (error) {
        console.error('Delete user error:', error);
        res.status(500).json({ message: 'Failed to delete user' });
    }
});

module.exports = router;