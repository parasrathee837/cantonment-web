const express = require('express');
const multer = require('multer');
const path = require('path');
const database = require('../config/database');
const router = express.Router();
const auth = require('../middleware/auth');
const NormalizedDBOperations = require('../../database/normalized-db-operations');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

const upload = multer({ storage });

// Initialize normalized DB operations
const dbOps = new NormalizedDBOperations(database.db);

// Get all admissions (staff) - uses the view for backward compatibility
router.get('/', auth, async (req, res) => {
  try {
    const admissions = await database.query(`
      SELECT * FROM admissions_view 
      ORDER BY created_at DESC
    `);
    res.json(admissions);
  } catch (error) {
    console.error('Get admissions error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get single staff member with complete information
router.get('/:staffId', auth, async (req, res) => {
  try {
    const staff = await dbOps.getStaffComplete(req.params.staffId);
    if (!staff) {
      return res.status(404).json({ message: 'Staff member not found' });
    }
    res.json(staff);
  } catch (error) {
    console.error('Get staff error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create new admission (staff)
router.post('/', auth, upload.single('photo'), async (req, res) => {
  try {
    // Prepare staff data from request body
    const staffData = {
      // Personal Information
      staff_id: req.body.staff_id,
      staff_name: req.body.staff_name || req.body.name,
      father_name: req.body.father_name || req.body.fatherName,
      mother_name: req.body.mother_name,
      grand_father_name: req.body.grand_father_name,
      spouse_name: req.body.spouse_name,
      date_of_birth: req.body.date_of_birth,
      age: req.body.age,
      gender: req.body.gender,
      nationality: req.body.nationality,
      religion: req.body.religion,
      category: req.body.category,
      marital_status: req.body.marital_status,
      blood_group: req.body.blood_group,
      
      // Contact Information
      permanent_address: req.body.permanent_address || req.body.address,
      present_address: req.body.present_address || req.body.address,
      communication_address: req.body.communication_address || req.body.address,
      mobile_number: req.body.mobile_number || req.body.phone,
      email: req.body.email,
      emergency_contact: req.body.emergency_contact,
      
      // Professional Information
      designation: req.body.designation,
      employee_type: req.body.employee_type,
      appointment_date: req.body.appointment_date,
      date_of_joining: req.body.date_of_joining,
      date_of_retirement: req.body.date_of_retirement,
      office_number: req.body.office_number,
      function_code: req.body.function_code,
      object_code: req.body.object_code,
      date_of_next_increment: req.body.date_of_next_increment,
      pension_scheme: req.body.pension_scheme,
      
      // Banking Information
      bank_name: req.body.bank_name,
      account_number: req.body.account_number,
      ifsc_code: req.body.ifsc_code,
      micr_code: req.body.micr_code,
      
      // Document Information
      aadhar_number: req.body.aadhar_number,
      pan_number: req.body.pan_number,
      voter_id: req.body.voter_id,
      ration_card: req.body.ration_card,
      driving_license: req.body.driving_license,
      passport_number: req.body.passport_number,
      pran_number: req.body.pran_number,
      uan_number: req.body.uan_number,
      esi_number: req.body.esi_number,
      gpf_number: req.body.gpf_number,
      
      // Salary Information
      pay_band: req.body.pay_band,
      grade_pay: req.body.grade_pay,
      pay_level: req.body.pay_level,
      pay_cell: req.body.pay_cell,
      basic_pay: req.body.basic_pay,
      da: req.body.da,
      hra: req.body.hra,
      ta: req.body.ta,
      special_pay: req.body.special_pay,
      special_allowance: req.body.special_allowance,
      other_allowance: req.body.other_allowance,
      gross_salary: req.body.gross_salary,
      net_salary: req.body.net_salary,
      
      // Additional fields
      photo: req.file ? req.file.filename : req.body.photo,
      documents: req.body.documents,
      children: req.body.children,
      status: req.body.status || 'approved',
      remarks: req.body.remarks
    };

    const result = await dbOps.insertStaff(staffData);
    
    // Fetch the newly created staff member
    const newStaff = await dbOps.getStaffComplete(result.staff_id);
    res.status(201).json(newStaff);
  } catch (error) {
    console.error('Create admission error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update admission (staff)
router.put('/:staffId', auth, upload.single('photo'), async (req, res) => {
  try {
    const { staffId } = req.params;
    
    // Organize updates by table
    const updates = {
      personal: {},
      banking: {},
      documents: {},
      salary: {}
    };
    
    // Map fields to appropriate tables
    const fieldMapping = {
      // Personal fields
      staff_name: 'personal',
      father_name: 'personal',
      mother_name: 'personal',
      grand_father_name: 'personal',
      spouse_name: 'personal',
      date_of_birth: 'personal',
      age: 'personal',
      gender: 'personal',
      nationality: 'personal',
      religion: 'personal',
      category: 'personal',
      marital_status: 'personal',
      blood_group: 'personal',
      permanent_address: 'personal',
      present_address: 'personal',
      communication_address: 'personal',
      mobile_number: 'personal',
      email: 'personal',
      emergency_contact: 'personal',
      designation: 'personal',
      employee_type: 'personal',
      appointment_date: 'personal',
      date_of_joining: 'personal',
      date_of_retirement: 'personal',
      office_number: 'personal',
      function_code: 'personal',
      object_code: 'personal',
      date_of_next_increment: 'personal',
      pension_scheme: 'personal',
      photo: 'personal',
      documents: 'personal',
      children: 'personal',
      status: 'personal',
      remarks: 'personal',
      
      // Banking fields
      bank_name: 'banking',
      account_number: 'banking',
      ifsc_code: 'banking',
      micr_code: 'banking',
      
      // Document fields
      aadhar_number: 'documents',
      pan_number: 'documents',
      voter_id: 'documents',
      ration_card: 'documents',
      driving_license: 'documents',
      passport_number: 'documents',
      pran_number: 'documents',
      uan_number: 'documents',
      esi_number: 'documents',
      gpf_number: 'documents',
      
      // Salary fields
      pay_band: 'salary',
      grade_pay: 'salary',
      pay_level: 'salary',
      pay_cell: 'salary',
      basic_pay: 'salary',
      da: 'salary',
      hra: 'salary',
      ta: 'salary',
      special_pay: 'salary',
      special_allowance: 'salary',
      other_allowance: 'salary',
      gross_salary: 'salary',
      net_salary: 'salary'
    };
    
    // Handle photo upload
    if (req.file) {
      req.body.photo = req.file.filename;
    }
    
    // Organize updates by table
    for (const [field, value] of Object.entries(req.body)) {
      const table = fieldMapping[field];
      if (table && value !== undefined) {
        updates[table][field] = value;
      }
    }
    
    // Remove empty update objects
    Object.keys(updates).forEach(key => {
      if (Object.keys(updates[key]).length === 0) {
        delete updates[key];
      }
    });
    
    // Perform update
    await dbOps.updateStaff(staffId, updates);
    
    // Fetch updated staff member
    const updatedStaff = await dbOps.getStaffComplete(staffId);
    if (!updatedStaff) {
      return res.status(404).json({ message: 'Staff member not found' });
    }
    
    res.json(updatedStaff);
  } catch (error) {
    console.error('Update admission error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Delete admission (staff)
router.delete('/:staffId', auth, async (req, res) => {
  try {
    const { staffId } = req.params;
    
    const result = await dbOps.deleteStaff(staffId);
    
    if (result.changes === 0) {
      return res.status(404).json({ message: 'Staff member not found' });
    }
    
    res.json({ message: 'Staff member deleted successfully' });
  } catch (error) {
    console.error('Delete admission error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Search staff with filters
router.get('/search', auth, async (req, res) => {
  try {
    const filters = {
      name: req.query.name,
      designation: req.query.designation,
      status: req.query.status
    };
    
    const results = await dbOps.searchStaff(filters);
    res.json(results);
  } catch (error) {
    console.error('Search staff error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get staff salary information
router.get('/:staffId/salary', auth, async (req, res) => {
  try {
    const salary = await database.query(
      'SELECT * FROM staff_salary WHERE staff_id = ?',
      [req.params.staffId]
    );
    
    if (salary.length === 0) {
      return res.status(404).json({ message: 'Salary information not found' });
    }
    
    res.json(salary[0]);
  } catch (error) {
    console.error('Get salary error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update staff salary
router.put('/:staffId/salary', auth, async (req, res) => {
  try {
    const result = await dbOps.updateStaffSalary(req.params.staffId, req.body);
    res.json(result);
  } catch (error) {
    console.error('Update salary error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;