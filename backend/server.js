const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Database configuration based on environment
const dbType = process.env.DB_TYPE || 'sqlite';
let database;

if (dbType === 'postgresql') {
    database = require('./config/postgresql-database');
} else {
    database = require('./config/database'); // SQLite fallback
}

const authRoutes = require('./routes/auth-enhanced');
const userRoutes = require('./routes/users-enhanced');
//const userNormalizedRoutes = require('./routes/users-normalized');
const admissionRoutes = require('./routes/admissions');
const designationRoutes = require('./routes/designations');
const fileUploadRoutes = require('./routes/file-uploads');
const adminRoutes = require('./routes/admin');

// New API routes
const leaveRoutes = require('./routes/leave');
const attendanceRoutes = require('./routes/attendance');
const payslipRoutes = require('./routes/payslip');
const documentsRoutes = require('./routes/documents');
const dashboardRoutes = require('./routes/dashboard');
const psVerificationRoutes = require('./routes/ps-verification');
const codesRoutes = require('./routes/codes');

const app = express();
const PORT = process.env.PORT || 5000;

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});

app.use(cors({
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://localhost:5000', 'http://127.0.0.1:5000', 'file://', '*'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  optionsSuccessStatus: 200
}));
app.use(helmet({
  crossOriginEmbedderPolicy: false,
  contentSecurityPolicy: false
}));
app.use(limiter);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static files from uploads directory
app.use('/uploads', express.static('uploads'));

// Serve the frontend HTML file
const path = require('path');
app.use(express.static(path.join(__dirname, '..')));

// Route to serve the main application
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../fixed-frontend.html'));
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
//app.use('/api/users-normalized', userNormalizedRoutes);
app.use('/api/admissions', admissionRoutes);
app.use('/api/designations', designationRoutes);
app.use('/api/files', fileUploadRoutes);
app.use('/api/admin', adminRoutes);

// Register new API routes
app.use('/api/leave', leaveRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/payslip', payslipRoutes);
app.use('/api/documents', documentsRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/ps-verification', psVerificationRoutes);
app.use('/api/codes', codesRoutes);

// Route alias for admin-designations (for backward compatibility)
app.delete('/api/admin-designations/:id', require('./middleware/auth'), async (req, res) => {
  // Check admin role
  if (req.user.role !== 'admin' && req.user.role !== 'super_admin') {
    return res.status(403).json({ message: 'Admin access required' });
  }

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

    // Delete the designation
    const result = await database.run('DELETE FROM designations WHERE id = ?', [id]);

    if (result.changes === 0) {
      return res.status(404).json({ message: 'Designation not found' });
    }

    res.json({
      success: true,
      message: 'Designation deleted successfully'
    });

  } catch (error) {
    console.error('Delete admin designation error:', error);
    res.status(500).json({ message: 'Failed to delete designation' });
  }
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Cantonment Board API is running' });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
