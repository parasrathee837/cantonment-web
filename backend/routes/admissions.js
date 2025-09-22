const express = require('express');
const multer = require('multer');
const path = require('path');
const database = require('../config/database');
const router = express.Router();
const auth = require('../middleware/auth');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

const upload = multer({ storage });

router.get('/', auth, async (req, res) => {
  try {
    const admissions = await database.query('SELECT * FROM admissions ORDER BY created_at DESC');
    res.json(admissions);
  } catch (error) {
    console.error('Get admissions error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Check if staff ID is unique
router.get('/check-staff-id/:staff_id', auth, async (req, res) => {
  try {
    const { staff_id } = req.params;
    
    // Check in both admissions (if staff_id column exists) and staff_personal tables
    const existingInAdmissions = await database.query(
      'SELECT id FROM admissions WHERE staff_id = ?', 
      [staff_id]
    ).catch(() => []); // Ignore error if staff_id column doesn't exist
    
    const existingInStaffPersonal = await database.query(
      'SELECT id FROM staff_personal WHERE staff_id = ?', 
      [staff_id]
    );
    
    const exists = existingInAdmissions.length > 0 || existingInStaffPersonal.length > 0;
    
    res.json({ 
      exists: exists,
      message: exists ? 'Staff ID already exists' : 'Staff ID is available'
    });
  } catch (error) {
    console.error('Check staff ID error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

router.post('/', auth, upload.single('photo'), async (req, res) => {
  try {
    const {
      name,
      fatherName,
      nationality,
      address,
      phone,
      designation,
      staffId
    } = req.body;

    // Check if staff ID is provided and unique
    if (staffId) {
      const existingInStaffPersonal = await database.query(
        'SELECT id FROM staff_personal WHERE staff_id = ?', 
        [staffId]
      );
      
      if (existingInStaffPersonal.length > 0) {
        return res.status(400).json({ message: 'Staff ID already exists' });
      }
    }

    const result = await database.run(
      `INSERT INTO admissions (name, father_name, nationality, address, phone, designation, photo_path, created_by, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [name, fatherName, nationality, address, phone, designation, req.file ? req.file.filename : null, req.user.userId, 'pending']
    );

    // If staffId is provided, also insert into staff_personal table
    if (staffId) {
      await database.run(
        `INSERT INTO staff_personal (staff_id, name, father_name, address, mobile_number) 
         VALUES (?, ?, ?, ?, ?)`,
        [staffId, name, fatherName, address, phone]
      );
    }

    const newAdmission = await database.query('SELECT * FROM admissions WHERE id = ?', [result.id]);
    res.status(201).json({
      ...newAdmission[0],
      staffId: staffId // Include staffId in response
    });
  } catch (error) {
    console.error('Create admission error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

router.put('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, fatherName, nationality, address, phone, designation, status } = req.body;

    await database.run(
      `UPDATE admissions SET name = ?, father_name = ?, nationality = ?, address = ?, phone = ?, designation = ?, status = ?, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [name, fatherName, nationality, address, phone, designation, status, id]
    );

    const updatedAdmission = await database.query('SELECT * FROM admissions WHERE id = ?', [id]);
    if (updatedAdmission.length === 0) {
      return res.status(404).json({ message: 'Admission not found' });
    }

    res.json(updatedAdmission[0]);
  } catch (error) {
    console.error('Update admission error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

router.delete('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await database.run('DELETE FROM admissions WHERE id = ?', [id]);
    
    if (result.changes === 0) {
      return res.status(404).json({ message: 'Admission not found' });
    }

    res.json({ message: 'Admission deleted successfully' });
  } catch (error) {
    console.error('Delete admission error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;