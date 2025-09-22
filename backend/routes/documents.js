const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const database = require('../config/database');
const router = express.Router();
const auth = require('../middleware/auth');

// Configure multer for document uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const { staff_id, document_type } = req.body;
        const uploadDir = `uploads/documents/${document_type || 'general'}/${staff_id || 'misc'}/`;
        
        // Create directory if it doesn't exist
        fs.mkdirSync(uploadDir, { recursive: true });
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const timestamp = Date.now();
        const extension = path.extname(file.originalname);
        const { staff_id, document_type } = req.body;
        const safeName = file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_');
        cb(null, `${document_type || 'doc'}_${staff_id || 'misc'}_${timestamp}_${safeName}${extension}`);
    }
});

const upload = multer({
    storage: storage,
    limits: { 
        fileSize: 10 * 1024 * 1024, // 10MB limit
        files: 5 // Maximum 5 files per request
    },
    fileFilter: (req, file, cb) => {
        // Allowed file types
        const allowedTypes = [
            'application/pdf',
            'image/jpeg', 'image/jpg', 'image/png', 'image/gif',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'text/plain'
        ];
        
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only PDF, Images, DOC, DOCX, XLS, XLSX, and TXT files are allowed.'));
        }
    }
});

// =====================================================================
// DOCUMENT MANAGEMENT
// =====================================================================

// Get all documents for a staff member
router.get('/:staff_id', auth, async (req, res) => {
    try {
        const { staff_id } = req.params;
        const { document_type, verification_status } = req.query;

        let query = `
            SELECT d.*, dc.category_name, u.username as uploaded_by_username
            FROM documents d
            LEFT JOIN document_categories dc ON d.category_id = dc.id
            LEFT JOIN users u ON d.uploaded_by = u.id
            WHERE d.staff_id = ? AND d.is_active = 1
        `;
        const params = [staff_id];

        if (document_type) {
            query += ' AND d.document_type = ?';
            params.push(document_type);
        }

        if (verification_status) {
            query += ' AND d.verification_status = ?';
            params.push(verification_status);
        }

        query += ' ORDER BY d.uploaded_at DESC';

        const documents = await database.query(query, params);

        // Get staff details
        const staff = await database.query(
            'SELECT * FROM admissions WHERE staff_id = ? OR id = ?',
            [staff_id, staff_id]
        );

        // Get document categories
        const categories = await database.query(
            'SELECT * FROM document_categories WHERE is_active = 1 ORDER BY category_name'
        );

        res.json({
            success: true,
            staff: staff[0] || null,
            documents: documents,
            categories: categories
        });

    } catch (error) {
        console.error('Get documents error:', error);
        res.status(500).json({ message: 'Failed to retrieve documents' });
    }
});

// Upload new document(s)
router.post('/upload', auth, upload.array('documents', 5), async (req, res) => {
    try {
        const {
            staff_id,
            document_type,
            category_id,
            description,
            is_mandatory,
            expiry_date
        } = req.body;

        if (!staff_id || !document_type || !req.files || req.files.length === 0) {
            return res.status(400).json({ 
                message: 'Missing required fields: staff_id, document_type, and files' 
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

        const uploadedDocuments = [];

        // Process each uploaded file
        for (const file of req.files) {
            const relativePath = file.path.replace(/\\/g, '/');
            const webPath = `/${relativePath}`;

            // Insert document record
            const result = await database.run(`
                INSERT INTO documents (
                    staff_id, document_type, document_name, file_path, file_size,
                    mime_type, category_id, description, is_mandatory, expiry_date,
                    verification_status, uploaded_by, uploaded_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, CURRENT_TIMESTAMP)
            `, [
                staff_id, document_type, file.originalname, webPath, file.size,
                file.mimetype, category_id, description, is_mandatory || false,
                expiry_date, req.user.userId
            ]);

            uploadedDocuments.push({
                id: result.lastID,
                document_name: file.originalname,
                file_path: webPath,
                file_size: file.size,
                mime_type: file.mimetype
            });
        }

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, activity_description, ip_address) VALUES (?, ?, ?, ?, ?)',
            [req.user.userId, 'upload', 'document', `Uploaded ${req.files.length} document(s) for staff ${staff_id}`, req.ip]
        );

        res.status(201).json({
            success: true,
            message: `${req.files.length} document(s) uploaded successfully`,
            documents: uploadedDocuments
        });

    } catch (error) {
        console.error('Upload document error:', error);
        res.status(500).json({ message: 'Failed to upload document(s)' });
    }
});

// Update document information
router.put('/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;
        const {
            document_name,
            document_type,
            category_id,
            description,
            is_mandatory,
            expiry_date,
            verification_status,
            verification_notes
        } = req.body;

        // Check if document exists
        const document = await database.query('SELECT * FROM documents WHERE id = ?', [id]);
        if (document.length === 0) {
            return res.status(404).json({ message: 'Document not found' });
        }

        // Update document
        const updateFields = [];
        const updateValues = [];

        if (document_name) {
            updateFields.push('document_name = ?');
            updateValues.push(document_name);
        }
        if (document_type) {
            updateFields.push('document_type = ?');
            updateValues.push(document_type);
        }
        if (category_id) {
            updateFields.push('category_id = ?');
            updateValues.push(category_id);
        }
        if (description !== undefined) {
            updateFields.push('description = ?');
            updateValues.push(description);
        }
        if (is_mandatory !== undefined) {
            updateFields.push('is_mandatory = ?');
            updateValues.push(is_mandatory);
        }
        if (expiry_date) {
            updateFields.push('expiry_date = ?');
            updateValues.push(expiry_date);
        }
        if (verification_status) {
            updateFields.push('verification_status = ?');
            updateValues.push(verification_status);
            
            if (verification_status === 'verified') {
                updateFields.push('verified_by = ?', 'verified_at = CURRENT_TIMESTAMP');
                updateValues.push(req.user.userId);
            }
        }
        if (verification_notes !== undefined) {
            updateFields.push('verification_notes = ?');
            updateValues.push(verification_notes);
        }

        updateFields.push('updated_at = CURRENT_TIMESTAMP');
        updateValues.push(id);

        await database.run(
            `UPDATE documents SET ${updateFields.join(', ')} WHERE id = ?`,
            updateValues
        );

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, 'update', 'document', id, 'Updated document information', req.ip]
        );

        res.json({
            success: true,
            message: 'Document updated successfully'
        });

    } catch (error) {
        console.error('Update document error:', error);
        res.status(500).json({ message: 'Failed to update document' });
    }
});

// Delete document (soft delete)
router.delete('/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;

        // Check if document exists
        const document = await database.query('SELECT * FROM documents WHERE id = ?', [id]);
        if (document.length === 0) {
            return res.status(404).json({ message: 'Document not found' });
        }

        // Soft delete (mark as inactive)
        await database.run(
            'UPDATE documents SET is_active = 0, deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
            [id]
        );

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, 'delete', 'document', id, `Deleted document: ${document[0].document_name}`, req.ip]
        );

        res.json({
            success: true,
            message: 'Document deleted successfully'
        });

    } catch (error) {
        console.error('Delete document error:', error);
        res.status(500).json({ message: 'Failed to delete document' });
    }
});

// Download document
router.get('/download/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;

        // Get document details
        const document = await database.query(
            'SELECT * FROM documents WHERE id = ? AND is_active = 1',
            [id]
        );

        if (document.length === 0) {
            return res.status(404).json({ message: 'Document not found' });
        }

        const doc = document[0];
        const filePath = path.join(__dirname, '..', doc.file_path);

        // Check if file exists
        if (!fs.existsSync(filePath)) {
            return res.status(404).json({ message: 'File not found on server' });
        }

        // Set appropriate headers
        res.setHeader('Content-Type', doc.mime_type);
        res.setHeader('Content-Disposition', `attachment; filename="${doc.document_name}"`);

        // Stream the file
        const fileStream = fs.createReadStream(filePath);
        fileStream.pipe(res);

        // Log the download
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, 'download', 'document', id, `Downloaded document: ${doc.document_name}`, req.ip]
        );

    } catch (error) {
        console.error('Download document error:', error);
        res.status(500).json({ message: 'Failed to download document' });
    }
});

// =====================================================================
// DOCUMENT CATEGORIES MANAGEMENT
// =====================================================================

// Get all document categories
router.get('/categories/all', auth, async (req, res) => {
    try {
        const categories = await database.query(
            'SELECT * FROM document_categories WHERE is_active = 1 ORDER BY category_name'
        );

        res.json({
            success: true,
            categories: categories
        });

    } catch (error) {
        console.error('Get document categories error:', error);
        res.status(500).json({ message: 'Failed to retrieve document categories' });
    }
});

// Create new document category (Admin only)
router.post('/categories', auth, async (req, res) => {
    try {
        // Check if user has admin privileges
        const user = await database.query('SELECT role FROM users WHERE id = ?', [req.user.userId]);
        if (user.length === 0 || !['admin', 'super_admin', 'hr'].includes(user[0].role)) {
            return res.status(403).json({ message: 'Access denied. Admin privileges required.' });
        }

        const { category_name, description, is_mandatory } = req.body;

        if (!category_name) {
            return res.status(400).json({ message: 'Category name is required' });
        }

        // Check if category already exists
        const existing = await database.query(
            'SELECT id FROM document_categories WHERE category_name = ?',
            [category_name]
        );

        if (existing.length > 0) {
            return res.status(400).json({ message: 'Document category already exists' });
        }

        // Create new category
        const result = await database.run(`
            INSERT INTO document_categories (category_name, description, is_mandatory, created_by)
            VALUES (?, ?, ?, ?)
        `, [category_name, description, is_mandatory || false, req.user.userId]);

        res.status(201).json({
            success: true,
            message: 'Document category created successfully',
            category_id: result.lastID
        });

    } catch (error) {
        console.error('Create document category error:', error);
        res.status(500).json({ message: 'Failed to create document category' });
    }
});

// =====================================================================
// VERIFICATION FUNCTIONS (Admin/HR)
// =====================================================================

// Verify document (Admin/HR only)
router.put('/:id/verify', auth, async (req, res) => {
    try {
        // Check if user has verification privileges
        const user = await database.query('SELECT role FROM users WHERE id = ?', [req.user.userId]);
        if (user.length === 0 || !['admin', 'super_admin', 'hr'].includes(user[0].role)) {
            return res.status(403).json({ message: 'Access denied. Verification privileges required.' });
        }

        const { id } = req.params;
        const { status, notes } = req.body; // status: 'verified', 'rejected'

        if (!['verified', 'rejected'].includes(status)) {
            return res.status(400).json({ message: 'Invalid status. Must be verified or rejected.' });
        }

        // Check if document exists
        const document = await database.query('SELECT * FROM documents WHERE id = ?', [id]);
        if (document.length === 0) {
            return res.status(404).json({ message: 'Document not found' });
        }

        // Update verification status
        await database.run(`
            UPDATE documents SET 
            verification_status = ?, verification_notes = ?, 
            verified_by = ?, verified_at = CURRENT_TIMESTAMP
            WHERE id = ?
        `, [status, notes, req.user.userId, id]);

        // Log the activity
        await database.run(
            'INSERT INTO user_activity (user_id, activity_type, entity_type, entity_id, activity_description, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.userId, 'verify', 'document', id, `${status} document: ${document[0].document_name}`, req.ip]
        );

        res.json({
            success: true,
            message: `Document ${status} successfully`
        });

    } catch (error) {
        console.error('Verify document error:', error);
        res.status(500).json({ message: 'Failed to verify document' });
    }
});

// Get documents pending verification (Admin/HR only)
router.get('/pending/verification', auth, async (req, res) => {
    try {
        // Check if user has verification privileges
        const user = await database.query('SELECT role FROM users WHERE id = ?', [req.user.userId]);
        if (user.length === 0 || !['admin', 'super_admin', 'hr'].includes(user[0].role)) {
            return res.status(403).json({ message: 'Access denied. Verification privileges required.' });
        }

        const pendingDocuments = await database.query(`
            SELECT d.*, a.name as staff_name, a.designation, dc.category_name, u.username as uploaded_by_username
            FROM documents d
            JOIN admissions a ON d.staff_id = a.staff_id
            LEFT JOIN document_categories dc ON d.category_id = dc.id
            LEFT JOIN users u ON d.uploaded_by = u.id
            WHERE d.verification_status = 'pending' AND d.is_active = 1
            ORDER BY d.uploaded_at DESC
        `);

        res.json({
            success: true,
            pending_documents: pendingDocuments,
            count: pendingDocuments.length
        });

    } catch (error) {
        console.error('Get pending documents error:', error);
        res.status(500).json({ message: 'Failed to retrieve pending documents' });
    }
});

// =====================================================================
// DOCUMENT STATISTICS
// =====================================================================

// Get document statistics for a staff member
router.get('/stats/:staff_id', auth, async (req, res) => {
    try {
        const { staff_id } = req.params;

        // Get document statistics
        const stats = await database.query(`
            SELECT 
                COUNT(*) as total_documents,
                COUNT(CASE WHEN verification_status = 'verified' THEN 1 END) as verified_documents,
                COUNT(CASE WHEN verification_status = 'pending' THEN 1 END) as pending_documents,
                COUNT(CASE WHEN verification_status = 'rejected' THEN 1 END) as rejected_documents,
                COUNT(CASE WHEN is_mandatory = 1 THEN 1 END) as mandatory_documents,
                COUNT(CASE WHEN is_mandatory = 1 AND verification_status = 'verified' THEN 1 END) as mandatory_verified,
                COALESCE(SUM(file_size), 0) as total_storage_used
            FROM documents
            WHERE staff_id = ? AND is_active = 1
        `, [staff_id]);

        // Get document type breakdown
        const typeBreakdown = await database.query(`
            SELECT document_type, COUNT(*) as count
            FROM documents
            WHERE staff_id = ? AND is_active = 1
            GROUP BY document_type
            ORDER BY count DESC
        `, [staff_id]);

        // Get recent uploads
        const recentUploads = await database.query(`
            SELECT document_name, document_type, verification_status, uploaded_at
            FROM documents
            WHERE staff_id = ? AND is_active = 1
            ORDER BY uploaded_at DESC
            LIMIT 5
        `, [staff_id]);

        res.json({
            success: true,
            staff_id: staff_id,
            statistics: stats[0],
            type_breakdown: typeBreakdown,
            recent_uploads: recentUploads
        });

    } catch (error) {
        console.error('Get document stats error:', error);
        res.status(500).json({ message: 'Failed to retrieve document statistics' });
    }
});

module.exports = router;