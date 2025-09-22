const express = require('express');
const router = express.Router();

// Get database instance based on configuration
const dbType = process.env.DB_TYPE || 'sqlite';
let db;

if (dbType === 'postgresql') {
    db = require('../config/postgresql-database');
} else {
    db = require('../config/database');
}

// Import authentication middleware
const auth = require('../middleware/auth');

// Apply authentication middleware to all routes
router.use(auth);

// GET /api/ps-verification - Get all PS verification records
router.get('/', async (req, res) => {
    try {
        console.log('PS Verification: Fetching all records');

        if (dbType === 'postgresql') {
            // PostgreSQL query
            const query = `
                SELECT 
                    pv.*,
                    a.staff_name,
                    a.father_name,
                    a.designation,
                    a.basic_salary,
                    a.da,
                    a.hra,
                    a.special_pay,
                    a.special_allowance,
                    a.other_allowance,
                    COALESCE(sd.total_deductions, 0) as total_deductions
                FROM ps_verifications pv
                INNER JOIN admissions a ON pv.staff_id = a.staff_id
                LEFT JOIN staff_deductions sd ON pv.staff_id = sd.staff_id AND sd.is_active = true
                ORDER BY pv.created_date DESC
            `;
            const result = await db.query(query);
            res.json(result.rows);
        } else {
            // SQLite query
            const query = `
                SELECT 
                    pv.*,
                    a.name as staff_name,
                    a.father_name as father_name,
                    a.designation,
                    CAST(a.id AS TEXT) as staff_id_key,
                    COALESCE(sd.total_deductions, 0) as total_deductions
                FROM ps_verifications pv
                INNER JOIN admissions a ON pv.staff_id = CAST(a.id AS TEXT)
                LEFT JOIN staff_deductions sd ON pv.staff_id = sd.staff_id AND sd.is_active = 1
                ORDER BY pv.created_date DESC
            `;
            const rows = await new Promise((resolve, reject) => {
                db.all(query, (err, rows) => {
                    if (err) reject(err);
                    else resolve(rows);
                });
            });
            res.json(rows);
        }
    } catch (error) {
        console.error('PS Verification fetch error:', error);
        res.status(500).json({ 
            error: 'Failed to fetch PS verification records',
            details: error.message 
        });
    }
});

// GET /api/ps-verification/:staffId - Get PS verification record for specific staff
router.get('/:staffId', async (req, res) => {
    try {
        const { staffId } = req.params;
        console.log('PS Verification: Fetching record for staff ID:', staffId);

        if (dbType === 'postgresql') {
            // PostgreSQL query
            const query = `
                SELECT 
                    pv.*,
                    a.staff_name,
                    a.father_name,
                    a.designation,
                    a.mobile_number,
                    a.basic_salary,
                    a.da,
                    a.hra,
                    a.special_pay,
                    a.special_allowance,
                    a.other_allowance,
                    COALESCE(sd.pf, 0) as pf,
                    COALESCE(sd.esi, 0) as esi,
                    COALESCE(sd.professional_tax, 0) as professional_tax,
                    COALESCE(sd.income_tax, 0) as income_tax,
                    COALESCE(sd.house_building_advance, 0) as house_building_advance,
                    COALESCE(sd.vehicle_advance, 0) as vehicle_advance,
                    COALESCE(sd.personal_loan, 0) as personal_loan,
                    COALESCE(sd.festival_advance, 0) as festival_advance,
                    COALESCE(sd.other_deduction1_name, '') as other_deduction1_name,
                    COALESCE(sd.other_deduction1_amount, 0) as other_deduction1_amount,
                    COALESCE(sd.other_deduction2_name, '') as other_deduction2_name,
                    COALESCE(sd.other_deduction2_amount, 0) as other_deduction2_amount,
                    COALESCE(sd.total_deductions, 0) as total_deductions
                FROM ps_verifications pv
                INNER JOIN admissions a ON pv.staff_id = a.staff_id
                LEFT JOIN staff_deductions sd ON pv.staff_id = sd.staff_id AND sd.is_active = true
                WHERE pv.staff_id = $1
            `;
            const result = await db.query(query, [staffId]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ error: 'PS verification record not found' });
            }
            
            res.json(result.rows[0]);
        } else {
            // SQLite query
            const query = `
                SELECT 
                    pv.*,
                    a.name as staff_name,
                    a.father_name as father_name,
                    a.designation,
                    a.phone as mobile_number,
                    CAST(a.id AS TEXT) as staff_id_key,
                    COALESCE(sd.pf, 0) as pf,
                    COALESCE(sd.esi, 0) as esi,
                    COALESCE(sd.professionalTax, 0) as professional_tax,
                    COALESCE(sd.incomeTax, 0) as income_tax,
                    COALESCE(sd.houseBuilding, 0) as house_building_advance,
                    COALESCE(sd.vehicleAdvance, 0) as vehicle_advance,
                    COALESCE(sd.personalLoan, 0) as personal_loan,
                    COALESCE(sd.festivalAdvance, 0) as festival_advance,
                    COALESCE(sd.otherDeduction1Name, '') as other_deduction1_name,
                    COALESCE(sd.otherDeduction1Amount, 0) as other_deduction1_amount,
                    COALESCE(sd.otherDeduction2Name, '') as other_deduction2_name,
                    COALESCE(sd.otherDeduction2Amount, 0) as other_deduction2_amount,
                    COALESCE(sd.total_deductions, 0) as total_deductions
                FROM ps_verifications pv
                INNER JOIN admissions a ON pv.staff_id = CAST(a.id AS TEXT)
                LEFT JOIN staff_deductions sd ON pv.staff_id = sd.staff_id AND sd.is_active = 1
                WHERE pv.staff_id = ?
            `;
            const row = await new Promise((resolve, reject) => {
                db.get(query, [staffId], (err, row) => {
                    if (err) reject(err);
                    else resolve(row);
                });
            });
            
            if (!row) {
                return res.status(404).json({ error: 'PS verification record not found' });
            }
            
            res.json(row);
        }
    } catch (error) {
        console.error('PS Verification fetch error:', error);
        res.status(500).json({ 
            error: 'Failed to fetch PS verification record',
            details: error.message 
        });
    }
});

// POST /api/ps-verification/initialize - Initialize PS verification records for all staff
router.post('/initialize', async (req, res) => {
    try {
        console.log('PS Verification: Initializing records for all staff');

        if (dbType === 'postgresql') {
            // PostgreSQL - Insert PS verification records for staff that don't have them
            const query = `
                INSERT INTO ps_verifications (staff_id, status, created_date, updated_date)
                SELECT a.staff_id, 'pending', NOW(), NOW()
                FROM admissions a
                WHERE a.status = 'approved'
                AND NOT EXISTS (
                    SELECT 1 FROM ps_verifications pv 
                    WHERE pv.staff_id = a.staff_id
                )
            `;
            const result = await db.query(query);
            res.json({ 
                message: 'PS verification records initialized successfully',
                recordsCreated: result.rowCount 
            });
        } else {
            // SQLite - Insert PS verification records for staff that don't have them
            const query = `
                INSERT INTO ps_verifications (staff_id, status, created_date, updated_date)
                SELECT CAST(a.id AS TEXT), 'pending', datetime('now'), datetime('now')
                FROM admissions a
                WHERE a.status = 'approved'
                AND NOT EXISTS (
                    SELECT 1 FROM ps_verifications pv 
                    WHERE pv.staff_id = CAST(a.id AS TEXT)
                )
            `;
            const result = await new Promise((resolve, reject) => {
                db.run(query, function(err) {
                    if (err) reject(err);
                    else resolve({ changes: this.changes });
                });
            });
            res.json({ 
                message: 'PS verification records initialized successfully',
                recordsCreated: result.changes 
            });
        }
    } catch (error) {
        console.error('PS Verification initialization error:', error);
        res.status(500).json({ 
            error: 'Failed to initialize PS verification records',
            details: error.message 
        });
    }
});

// PUT /api/ps-verification/:staffId/approve - Approve PS verification
router.put('/:staffId/approve', async (req, res) => {
    try {
        const { staffId } = req.params;
        const { approvedBy, remarks } = req.body;
        
        console.log('PS Verification: Approving record for staff ID:', staffId);

        if (dbType === 'postgresql') {
            // PostgreSQL update
            const query = `
                UPDATE ps_verifications 
                SET status = 'approved',
                    approved_by = $1,
                    approved_date = NOW(),
                    remarks = $2,
                    updated_date = NOW()
                WHERE staff_id = $3
                RETURNING *
            `;
            const result = await db.query(query, [approvedBy, remarks || '', staffId]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ error: 'PS verification record not found' });
            }
            
            res.json({ 
                message: 'PS verification approved successfully',
                record: result.rows[0] 
            });
        } else {
            // SQLite update
            const query = `
                UPDATE ps_verifications 
                SET status = 'approved',
                    approved_by = ?,
                    approved_date = datetime('now'),
                    remarks = ?,
                    updated_date = datetime('now')
                WHERE staff_id = ?
            `;
            const result = await new Promise((resolve, reject) => {
                db.run(query, [approvedBy, remarks || '', staffId], function(err) {
                    if (err) reject(err);
                    else resolve({ changes: this.changes });
                });
            });
            
            if (result.changes === 0) {
                return res.status(404).json({ error: 'PS verification record not found' });
            }
            
            res.json({ 
                message: 'PS verification approved successfully',
                staffId: staffId 
            });
        }
    } catch (error) {
        console.error('PS Verification approval error:', error);
        res.status(500).json({ 
            error: 'Failed to approve PS verification',
            details: error.message 
        });
    }
});

// PUT /api/ps-verification/:staffId/reject - Reject PS verification
router.put('/:staffId/reject', async (req, res) => {
    try {
        const { staffId } = req.params;
        const { rejectedBy, remarks } = req.body;
        
        if (!remarks || remarks.trim() === '') {
            return res.status(400).json({ error: 'Rejection reason is required' });
        }
        
        console.log('PS Verification: Rejecting record for staff ID:', staffId);

        if (dbType === 'postgresql') {
            // PostgreSQL update
            const query = `
                UPDATE ps_verifications 
                SET status = 'rejected',
                    rejected_by = $1,
                    rejected_date = NOW(),
                    remarks = $2,
                    updated_date = NOW()
                WHERE staff_id = $3
                RETURNING *
            `;
            const result = await db.query(query, [rejectedBy, remarks.trim(), staffId]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ error: 'PS verification record not found' });
            }
            
            res.json({ 
                message: 'PS verification rejected successfully',
                record: result.rows[0] 
            });
        } else {
            // SQLite update
            const query = `
                UPDATE ps_verifications 
                SET status = 'rejected',
                    rejected_by = ?,
                    rejected_date = datetime('now'),
                    remarks = ?,
                    updated_date = datetime('now')
                WHERE staff_id = ?
            `;
            const result = await new Promise((resolve, reject) => {
                db.run(query, [rejectedBy, remarks.trim(), staffId], function(err) {
                    if (err) reject(err);
                    else resolve({ changes: this.changes });
                });
            });
            
            if (result.changes === 0) {
                return res.status(404).json({ error: 'PS verification record not found' });
            }
            
            res.json({ 
                message: 'PS verification rejected successfully',
                staffId: staffId 
            });
        }
    } catch (error) {
        console.error('PS Verification rejection error:', error);
        res.status(500).json({ 
            error: 'Failed to reject PS verification',
            details: error.message 
        });
    }
});

// GET /api/ps-verification/stats - Get PS verification statistics
router.get('/stats', async (req, res) => {
    try {
        console.log('PS Verification: Fetching statistics');

        if (dbType === 'postgresql') {
            // PostgreSQL query
            const query = `
                SELECT 
                    COUNT(*) as total_records,
                    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_count,
                    SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved_count,
                    SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected_count
                FROM ps_verifications
            `;
            const result = await db.query(query);
            res.json(result.rows[0]);
        } else {
            // SQLite query
            const query = `
                SELECT 
                    COUNT(*) as total_records,
                    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_count,
                    SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved_count,
                    SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected_count
                FROM ps_verifications
            `;
            const row = await new Promise((resolve, reject) => {
                db.get(query, (err, row) => {
                    if (err) reject(err);
                    else resolve(row);
                });
            });
            res.json(row);
        }
    } catch (error) {
        console.error('PS Verification stats error:', error);
        res.status(500).json({ 
            error: 'Failed to fetch PS verification statistics',
            details: error.message 
        });
    }
});

// PUT /api/ps-verification/:staffId/reset - Reset PS verification status to pending
router.put('/:staffId/reset', async (req, res) => {
    try {
        const { staffId } = req.params;
        console.log('PS Verification: Resetting status for staff ID:', staffId);

        if (dbType === 'postgresql') {
            // PostgreSQL update
            const query = `
                UPDATE ps_verifications 
                SET status = 'pending',
                    approved_by = NULL,
                    approved_date = NULL,
                    rejected_by = NULL,
                    rejected_date = NULL,
                    remarks = '',
                    updated_date = NOW()
                WHERE staff_id = $1
                RETURNING *
            `;
            const result = await db.query(query, [staffId]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ error: 'PS verification record not found' });
            }
            
            res.json({ 
                message: 'PS verification status reset successfully',
                record: result.rows[0] 
            });
        } else {
            // SQLite update
            const query = `
                UPDATE ps_verifications 
                SET status = 'pending',
                    approved_by = NULL,
                    approved_date = NULL,
                    rejected_by = NULL,
                    rejected_date = NULL,
                    remarks = '',
                    updated_date = datetime('now')
                WHERE staff_id = ?
            `;
            const result = await new Promise((resolve, reject) => {
                db.run(query, [staffId], function(err) {
                    if (err) reject(err);
                    else resolve({ changes: this.changes });
                });
            });
            
            if (result.changes === 0) {
                return res.status(404).json({ error: 'PS verification record not found' });
            }
            
            res.json({ 
                message: 'PS verification status reset successfully',
                staffId: staffId 
            });
        }
    } catch (error) {
        console.error('PS Verification reset error:', error);
        res.status(500).json({ 
            error: 'Failed to reset PS verification status',
            details: error.message 
        });
    }
});

module.exports = router;