const express = require('express');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
const database = require('../config/database');
const NormalizedUserOperations = require('../../database/normalized-user-operations');
const router = express.Router();
const auth = require('../middleware/auth');

// Initialize normalized user operations
const userOps = new NormalizedUserOperations(database.db);

// Configure multer for profile photo uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/profiles/');
    },
    filename: (req, file, cb) => {
        const timestamp = Date.now();
        const extension = path.extname(file.originalname);
        cb(null, `profile_${timestamp}${extension}`);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 2 * 1024 * 1024 }, // 2MB limit
    fileFilter: (req, file, cb) => {
        const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only JPEG, PNG and GIF are allowed.'));
        }
    }
});

// Get all users with complete information
router.get('/', auth, async (req, res) => {
    try {
        const users = await userOps.getAllUsersComplete();
        
        // Remove passwords from response
        const safeUsers = users.map(user => {
            const { password, ...safeUser } = user;
            return safeUser;
        });
        
        res.json(safeUsers);
    } catch (error) {
        console.error('Get users error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get single user with complete information
router.get('/:userId', auth, async (req, res) => {
    try {
        const user = await userOps.getUserComplete(req.params.userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        // Remove password from response
        const { password, ...safeUser } = user;
        res.json(safeUser);
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Create new user with complete information
router.post('/', auth, upload.single('profile_photo'), async (req, res) => {
    try {
        // Extract all user data from request body
        const userData = {
            // Main user fields
            username: req.body.username,
            password: req.body.password,
            role: req.body.role || 'user',
            status: req.body.status || 'active',
            full_name: req.body.full_name,
            email: req.body.email,
            phone: req.body.phone,
            
            // Personal information
            date_of_birth: req.body.date_of_birth,
            age: req.body.age,
            gender: req.body.gender,
            father_name: req.body.father_name,
            mother_name: req.body.mother_name,
            grand_father_name: req.body.grand_father_name,
            marital_status: req.body.marital_status,
            blood_group: req.body.blood_group,
            nationality: req.body.nationality || 'Indian',
            religion: req.body.religion,
            category: req.body.category,
            
            // Contact information
            mobile_number: req.body.mobile_number,
            address: req.body.address,
            permanent_address: req.body.permanent_address || req.body.address,
            present_address: req.body.present_address || req.body.address,
            emergency_contact: req.body.emergency_contact,
            
            // Professional information
            designation_id: req.body.designation_id,
            designation: req.body.designation,
            department: req.body.department,
            employee_id: req.body.employee_id,
            employee_type: req.body.employee_type,
            appointment_date: req.body.appointment_date,
            date_of_joining: req.body.date_of_joining,
            office_number: req.body.office_number,
            function_code: req.body.function_code,
            object_code: req.body.object_code,
            
            // Document information
            aadhar_number: req.body.aadhar_number,
            pan_number: req.body.pan_number,
            voter_id: req.body.voter_id,
            ration_card: req.body.ration_card,
            driving_license: req.body.driving_license,
            passport_number: req.body.passport_number,
            
            // File upload
            profile_photo: req.file ? req.file.filename : null
        };

        // Hash password before storing
        if (userData.password) {
            userData.password = await bcrypt.hash(userData.password, 12);
        } else {
            return res.status(400).json({ message: 'Password is required' });
        }

        // Check if username already exists
        const existingUser = await database.query(
            'SELECT id FROM users WHERE username = ?',
            [userData.username]
        );

        if (existingUser.length > 0) {
            return res.status(400).json({ message: 'Username already exists' });
        }

        // Check if email already exists (if provided)
        if (userData.email) {
            const existingEmail = await database.query(
                'SELECT id FROM users WHERE email = ?',
                [userData.email]
            );

            if (existingEmail.length > 0) {
                return res.status(400).json({ message: 'Email already exists' });
            }
        }

        // Create the user
        const result = await userOps.insertUser(userData);
        
        if (result.success) {
            // Fetch the newly created user
            const newUser = await userOps.getUserComplete(result.user_id);
            const { password, ...safeUser } = newUser;
            
            res.status(201).json({
                success: true,
                message: 'User created successfully',
                user: safeUser
            });
        } else {
            res.status(500).json({ message: 'Failed to create user' });
        }

    } catch (error) {
        console.error('Create user error:', error);
        res.status(500).json({ 
            message: 'Server error', 
            error: error.message 
        });
    }
});

// Update user
router.put('/:userId', auth, upload.single('profile_photo'), async (req, res) => {
    try {
        const { userId } = req.params;
        
        // Organize updates by table
        const updates = {
            main: {},
            personal: {},
            contact: {},
            professional: {},
            documents: {}
        };
        
        // Map fields to appropriate tables
        const fieldMapping = {
            // Main user fields
            username: 'main',
            role: 'main',
            status: 'main',
            full_name: 'main',
            email: 'main',
            phone: 'main',
            
            // Personal fields
            date_of_birth: 'personal',
            age: 'personal',
            gender: 'personal',
            father_name: 'personal',
            mother_name: 'personal',
            grand_father_name: 'personal',
            marital_status: 'personal',
            blood_group: 'personal',
            nationality: 'personal',
            religion: 'personal',
            category: 'personal',
            
            // Contact fields
            mobile_number: 'contact',
            address: 'contact',
            permanent_address: 'contact',
            present_address: 'contact',
            emergency_contact: 'contact',
            
            // Professional fields
            designation_id: 'professional',
            designation: 'professional',
            department: 'professional',
            employee_id: 'professional',
            employee_type: 'professional',
            appointment_date: 'professional',
            date_of_joining: 'professional',
            office_number: 'professional',
            function_code: 'professional',
            object_code: 'professional',
            
            // Document fields
            aadhar_number: 'documents',
            pan_number: 'documents',
            voter_id: 'documents',
            ration_card: 'documents',
            driving_license: 'documents',
            passport_number: 'documents'
        };
        
        // Handle profile photo upload
        if (req.file) {
            updates.main.profile_photo = req.file.filename;
        }
        
        // Organize updates by table
        for (const [field, value] of Object.entries(req.body)) {
            const table = fieldMapping[field];
            if (table && value !== undefined && value !== '') {
                updates[table][field] = value;
            }
        }
        
        // Handle password update separately
        if (req.body.password) {
            updates.main.password = await bcrypt.hash(req.body.password, 12);
        }
        
        // Remove empty update objects
        Object.keys(updates).forEach(key => {
            if (Object.keys(updates[key]).length === 0) {
                delete updates[key];
            }
        });
        
        // Perform update
        await userOps.updateUser(userId, updates);
        
        // Fetch updated user
        const updatedUser = await userOps.getUserComplete(userId);
        if (!updatedUser) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        const { password, ...safeUser } = updatedUser;
        res.json({
            success: true,
            message: 'User updated successfully',
            user: safeUser
        });
        
    } catch (error) {
        console.error('Update user error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Delete user
router.delete('/:userId', auth, async (req, res) => {
    try {
        const { userId } = req.params;
        
        const result = await userOps.deleteUser(userId);
        
        if (result.changes === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        res.json({ 
            success: true, 
            message: 'User deleted successfully' 
        });
    } catch (error) {
        console.error('Delete user error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Search users with filters
router.get('/search', auth, async (req, res) => {
    try {
        const filters = {
            name: req.query.name,
            designation: req.query.designation,
            status: req.query.status,
            department: req.query.department
        };
        
        const results = await userOps.searchUsers(filters);
        
        // Remove passwords from response
        const safeResults = results.map(user => {
            const { password, ...safeUser } = user;
            return safeUser;
        });
        
        res.json(safeResults);
    } catch (error) {
        console.error('Search users error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get user permissions (existing functionality)
router.get('/:userId/permissions', auth, async (req, res) => {
    try {
        const permissions = await database.query(
            'SELECT * FROM user_permissions WHERE user_id = ?',
            [req.params.userId]
        );
        
        res.json(permissions);
    } catch (error) {
        console.error('Get permissions error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Update user permissions (existing functionality)
router.put('/:userId/permissions', auth, async (req, res) => {
    try {
        const { userId } = req.params;
        const { permissions } = req.body;
        
        // Delete existing permissions
        await database.run('DELETE FROM user_permissions WHERE user_id = ?', [userId]);
        
        // Insert new permissions
        if (permissions && permissions.length > 0) {
            const placeholders = permissions.map(() => '(?, ?, ?, ?)').join(', ');
            const values = [];
            
            permissions.forEach(perm => {
                values.push(userId, perm.tab, perm.permission, 1);
            });
            
            await database.run(
                `INSERT INTO user_permissions (user_id, tab_name, permission_type, is_granted) VALUES ${placeholders}`,
                values
            );
        }
        
        res.json({ 
            success: true, 
            message: 'Permissions updated successfully' 
        });
    } catch (error) {
        console.error('Update permissions error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router;