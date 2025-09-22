const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const database = require('../config/database');
const router = express.Router();
const auth = require('../middleware/auth');

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

// Configure multer for file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadsDir);
    },
    filename: (req, file, cb) => {
        const timestamp = Date.now();
        const extension = path.extname(file.originalname);
        const filename = `${timestamp}${extension}`;
        cb(null, filename);
    }
});

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB limit
    },
    fileFilter: (req, file, cb) => {
        // Define allowed file types based on upload type
        const allowedTypes = {
            'staff_photo': ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'],
            'staff_document': ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png', 
                             'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
            'leave_document': ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png', 
                             'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
            'user_photo': ['image/jpeg', 'image/jpg', 'image/png', 'image/gif']
        };

        const uploadType = req.body.upload_type || req.query.upload_type || 'staff_document';
        const allowed = allowedTypes[uploadType] || allowedTypes['staff_document'];

        if (allowed.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error(`File type ${file.mimetype} not allowed for ${uploadType}`));
        }
    }
});

// Upload single file
router.post('/upload', auth, upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        const {
            upload_type = 'staff_document',
            related_table = '',
            related_id = '',
            description = '',
            category_id = null
        } = req.body;

        // Insert file record into database
        const fileData = {
            original_filename: req.file.originalname,
            stored_filename: req.file.filename,
            file_path: `/uploads/${req.file.filename}`,
            file_size: req.file.size,
            mime_type: req.file.mimetype,
            file_extension: path.extname(req.file.originalname).toLowerCase(),
            upload_type: upload_type,
            related_table: related_table,
            related_id: related_id,
            uploaded_by: req.user.userId,
            upload_ip: req.ip,
            description: description
        };

        const query = `
            INSERT INTO file_uploads (
                original_filename, stored_filename, file_path, file_size, mime_type, 
                file_extension, upload_type, related_table, related_id, uploaded_by, 
                upload_ip, description
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        const result = await database.run(query, [
            fileData.original_filename,
            fileData.stored_filename,
            fileData.file_path,
            fileData.file_size,
            fileData.mime_type,
            fileData.file_extension,
            fileData.upload_type,
            fileData.related_table,
            fileData.related_id,
            fileData.uploaded_by,
            fileData.upload_ip,
            fileData.description
        ]);

        // If it's a staff photo, also update staff_personal table
        if (upload_type === 'staff_photo' && related_id) {
            await database.run(
                'UPDATE staff_personal SET photo = ?, photo_file_id = ? WHERE staff_id = ?',
                [fileData.file_path, result.id, related_id]
            );
        }

        // If it's a document, also insert into documents table if needed
        if (upload_type === 'staff_document' && related_id) {
            await database.run(`
                INSERT OR IGNORE INTO documents (
                    staff_id, document_type, document_name, file_path, 
                    file_size, uploaded_by, category_id
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            `, [
                related_id,
                description || 'General Document',
                fileData.original_filename,
                fileData.file_path,
                fileData.file_size,
                fileData.uploaded_by,
                category_id
            ]);
        }

        res.status(201).json({
            success: true,
            message: 'File uploaded successfully',
            file: {
                id: result.id,
                filename: fileData.stored_filename,
                original_name: fileData.original_filename,
                path: fileData.file_path,
                size: fileData.file_size,
                type: fileData.mime_type,
                upload_date: new Date().toISOString()
            }
        });

    } catch (error) {
        console.error('File upload error:', error);
        
        // Clean up uploaded file if database insertion failed
        if (req.file) {
            fs.unlink(req.file.path, (err) => {
                if (err) console.error('Failed to delete file:', err);
            });
        }

        res.status(500).json({ 
            message: 'File upload failed', 
            error: error.message 
        });
    }
});

// Upload multiple files
router.post('/upload-multiple', auth, upload.array('files', 10), async (req, res) => {
    try {
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ message: 'No files uploaded' });
        }

        const {
            upload_type = 'staff_document',
            related_table = '',
            related_id = '',
            description = ''
        } = req.body;

        const uploadedFiles = [];
        const errors = [];

        for (const file of req.files) {
            try {
                const fileData = {
                    original_filename: file.originalname,
                    stored_filename: file.filename,
                    file_path: `/uploads/${file.filename}`,
                    file_size: file.size,
                    mime_type: file.mimetype,
                    file_extension: path.extname(file.originalname).toLowerCase(),
                    upload_type: upload_type,
                    related_table: related_table,
                    related_id: related_id,
                    uploaded_by: req.user.userId,
                    upload_ip: req.ip,
                    description: description
                };

                const query = `
                    INSERT INTO file_uploads (
                        original_filename, stored_filename, file_path, file_size, mime_type, 
                        file_extension, upload_type, related_table, related_id, uploaded_by, 
                        upload_ip, description
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                `;

                const result = await database.run(query, [
                    fileData.original_filename,
                    fileData.stored_filename,
                    fileData.file_path,
                    fileData.file_size,
                    fileData.mime_type,
                    fileData.file_extension,
                    fileData.upload_type,
                    fileData.related_table,
                    fileData.related_id,
                    fileData.uploaded_by,
                    fileData.upload_ip,
                    fileData.description
                ]);

                uploadedFiles.push({
                    id: result.id,
                    filename: fileData.stored_filename,
                    original_name: fileData.original_filename,
                    path: fileData.file_path,
                    size: fileData.file_size,
                    type: fileData.mime_type
                });

            } catch (error) {
                errors.push({
                    filename: file.originalname,
                    error: error.message
                });
            }
        }

        res.status(201).json({
            success: true,
            message: `${uploadedFiles.length} files uploaded successfully`,
            uploaded_files: uploadedFiles,
            errors: errors
        });

    } catch (error) {
        console.error('Multiple file upload error:', error);
        res.status(500).json({ 
            message: 'File upload failed', 
            error: error.message 
        });
    }
});

// Get file by ID
router.get('/file/:id', auth, async (req, res) => {
    try {
        const file = await database.query(
            'SELECT * FROM file_uploads WHERE id = ? AND is_deleted = 0',
            [req.params.id]
        );

        if (file.length === 0) {
            return res.status(404).json({ message: 'File not found' });
        }

        const filePath = path.join(__dirname, '..', file[0].file_path);
        
        if (!fs.existsSync(filePath)) {
            return res.status(404).json({ message: 'File not found on disk' });
        }

        res.sendFile(filePath);

    } catch (error) {
        console.error('File retrieval error:', error);
        res.status(500).json({ message: 'Failed to retrieve file' });
    }
});

// Get files for a specific record
router.get('/files/:relatedTable/:relatedId', auth, async (req, res) => {
    try {
        const { relatedTable, relatedId } = req.params;
        const { upload_type } = req.query;

        let query = `
            SELECT fu.*, dc.name as category_name 
            FROM file_uploads fu
            LEFT JOIN documents d ON fu.file_path = d.file_path
            LEFT JOIN document_categories dc ON d.category_id = dc.id
            WHERE fu.related_table = ? AND fu.related_id = ? AND fu.is_deleted = 0
        `;
        const params = [relatedTable, relatedId];

        if (upload_type) {
            query += ' AND fu.upload_type = ?';
            params.push(upload_type);
        }

        query += ' ORDER BY fu.upload_date DESC';

        const files = await database.query(query, params);

        res.json({
            success: true,
            files: files.map(file => ({
                id: file.id,
                filename: file.original_filename,
                stored_name: file.stored_filename,
                path: file.file_path,
                size: file.file_size,
                type: file.mime_type,
                upload_type: file.upload_type,
                category: file.category_name,
                upload_date: file.upload_date,
                is_verified: file.is_verified
            }))
        });

    } catch (error) {
        console.error('File listing error:', error);
        res.status(500).json({ message: 'Failed to retrieve files' });
    }
});

// Delete file
router.delete('/file/:id', auth, async (req, res) => {
    try {
        const fileId = req.params.id;

        // Mark file as deleted in database (soft delete)
        await database.run(
            'UPDATE file_uploads SET is_deleted = 1, deleted_by = ?, deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
            [req.user.userId, fileId]
        );

        res.json({
            success: true,
            message: 'File deleted successfully'
        });

    } catch (error) {
        console.error('File deletion error:', error);
        res.status(500).json({ message: 'Failed to delete file' });
    }
});

// Get document categories
router.get('/categories', auth, async (req, res) => {
    try {
        const categories = await database.query(
            'SELECT * FROM document_categories WHERE is_active = 1 ORDER BY name'
        );

        res.json({
            success: true,
            categories: categories
        });

    } catch (error) {
        console.error('Categories retrieval error:', error);
        res.status(500).json({ message: 'Failed to retrieve categories' });
    }
});

module.exports = router;