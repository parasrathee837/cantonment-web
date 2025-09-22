@echo off
echo ===========================================================
echo   EMERGENCY SERVER.JS FIX - WINDOWS
echo ===========================================================
echo.
echo This will completely replace your corrupted server.js
echo with a working version for PostgreSQL.
echo.
pause

cd /d "C:\CBA_Portal\cantonment-web\backend"

echo Backing up corrupted file...
if exist server.js ren server.js server-corrupted.js

echo Creating new server.js...
(
echo const express = require('express'^);
echo const cors = require('cors'^);
echo const helmet = require('helmet'^);
echo const rateLimit = require('express-rate-limit'^);
echo const path = require('path'^);
echo require('dotenv'^).config(^);
echo.
echo const dbType = process.env.DB_TYPE ^|^| 'sqlite';
echo let database;
echo.
echo if (dbType === 'postgresql'^) {
echo     database = require('./config/postgresql-database'^);
echo } else {
echo     database = require('./config/database'^);
echo }
echo.
echo const authRoutes = require('./routes/auth-enhanced'^);
echo const userRoutes = require('./routes/users-enhanced'^);
echo const admissionRoutes = require('./routes/admissions'^);
echo const designationRoutes = require('./routes/designations'^);
echo const fileUploadRoutes = require('./routes/file-uploads'^);
echo const adminRoutes = require('./routes/admin'^);
echo.
echo const app = express(^);
echo const PORT = process.env.PORT ^|^| 5000;
echo.
echo const limiter = rateLimit(^{
echo   windowMs: 15 * 60 * 1000,
echo   max: 100
echo }^);
echo.
echo app.use(cors(^{
echo   origin: '*',
echo   credentials: true
echo }^^);
echo.
echo app.use(helmet(^{
echo   crossOriginEmbedderPolicy: false,
echo   contentSecurityPolicy: false
echo }^^);
echo.
echo app.use(limiter^);
echo app.use(express.json(^)^);
echo app.use(express.urlencoded(^{ extended: true }^^);
echo app.use('/uploads', express.static('uploads'^^^)^);
echo.
echo app.use('/api/auth', authRoutes^);
echo app.use('/api/users', userRoutes^);
echo app.use('/api/admissions', admissionRoutes^);
echo app.use('/api/designations', designationRoutes^);
echo app.use('/api/file-uploads', fileUploadRoutes^);
echo app.use('/api/admin', adminRoutes^);
echo.
echo app.use(express.static('../'^^^)^);
echo.
echo app.get('*', (req, res^^^) =^> {
echo   res.sendFile(path.join(__dirname, '../fixed-frontend.html'^^^)^);
echo }^);
echo.
echo app.listen(PORT, '0.0.0.0', (^^^) =^> {
echo   console.log(`Server running on port ${PORT}`^^^);
echo   console.log(`Database type: ${dbType}`^^^);
echo   console.log(`Access at: http://localhost:${PORT}`^^^);
echo }^);
) > server.js

echo Testing syntax...
node -c server.js
if errorlevel 1 (
    echo FAILED - Syntax still broken
    pause
    exit /b 1
)

echo ✓ SUCCESS - Server.js fixed!
echo.
echo Now try: start-cba-portal-postgresql.bat
echo.
pause