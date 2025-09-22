@echo off
color 0E
echo ===========================================================
echo   QUICK SERVER.JS SYNTAX FIX
echo ===========================================================
echo.
echo Replacing corrupted server.js with clean version...
echo.

cd /d "C:\CBA_Portal\cantonment-web\backend"

:: Backup current file
if exist server.js (
    copy server.js server-backup-%date:~-4,4%%date:~-10,2%%date:~-7,2%.js >nul 2>&1
    echo ✓ Backup created
)

:: Copy the working server file from Linux version
echo Downloading clean server.js...

:: Create clean server.js using PowerShell
powershell -Command "& {
$content = @'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');
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
const userNormalizedRoutes = require('./routes/users-normalized');
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

// Mount routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/users-normalized', userNormalizedRoutes);
app.use('/api/admissions', admissionRoutes);
app.use('/api/designations', designationRoutes);
app.use('/api/file-uploads', fileUploadRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/leave', leaveRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/payslip', payslipRoutes);
app.use('/api/documents', documentsRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/ps-verification', psVerificationRoutes);
app.use('/api/codes', codesRoutes);

// Serve the frontend
app.use(express.static('../'));

// Catch-all handler for SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../fixed-frontend.html'));
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Global error handler:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Received SIGINT. Graceful shutdown...');
  
  if (database && database.close) {
    try {
      await database.close();
      console.log('Database connection closed.');
    } catch (error) {
      console.error('Error closing database:', error);
    }
  }
  
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('Received SIGTERM. Graceful shutdown...');
  
  if (database && database.close) {
    try {
      await database.close();
      console.log('Database connection closed.');
    } catch (error) {
      console.error('Error closing database:', error);
    }
  }
  
  process.exit(0);
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Database type: ${dbType}`);
  console.log(`Local access: http://localhost:${PORT}`);
  
  // Get network IP for local network access
  const os = require('os');
  const interfaces = os.networkInterfaces();
  Object.keys(interfaces).forEach(iface => {
    interfaces[iface].forEach(alias => {
      if (alias.family === 'IPv4' && !alias.internal) {
        console.log(`Network access: http://${alias.address}:${PORT}`);
      }
    });
  });
});
'@
$content | Out-File -FilePath 'server.js' -Encoding UTF8
}"

echo ✓ Clean server.js created

:: Test syntax
echo Testing syntax...
node -c server.js
if errorlevel 1 (
    echo ❌ Still has syntax errors
    pause
    exit /b 1
) else (
    echo ✓ Syntax is valid
)

echo.
echo ===========================================================
echo   ✓ SERVER.JS FIXED SUCCESSFULLY!
echo ===========================================================
echo.
echo Now try starting your server:
echo start-cba-portal-postgresql.bat
echo.
pause