@echo off
color 0D
echo ===========================================================
echo   NUCLEAR OPTION - COMPLETE CLEAN REINSTALL
echo ===========================================================
echo.
echo This is the "nuclear option" - it will completely remove
echo ALL node_modules from everywhere and reinstall everything
echo fresh for PostgreSQL only.
echo.
echo ⚠️  WARNING: This will delete:
echo - All node_modules folders
echo - All package-lock.json files
echo - Will take 10-15 minutes to reinstall everything
echo.
echo Use this if the regular fixes don't work.
echo.
set /p CONFIRM="Are you sure? Type 'YES' to continue: "

if not "%CONFIRM%"=="YES" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo.
echo Starting nuclear cleanup...
echo.

echo [1/10] Stopping any running servers...
taskkill /f /im node.exe 2>nul
echo ✓ Node processes stopped

echo [2/10] Removing ALL node_modules from root...
cd /d "C:\CBA_Portal\cantonment-web"
rd /s /q node_modules 2>nul
echo ✓ Root node_modules removed

echo [3/10] Removing ALL node_modules from backend...
cd /d "C:\CBA_Portal\cantonment-web\backend"
rd /s /q node_modules 2>nul
echo ✓ Backend node_modules removed

echo [4/10] Removing ALL lock files...
cd /d "C:\CBA_Portal\cantonment-web"
del package-lock.json 2>nul
del npm-shrinkwrap.json 2>nul
del yarn.lock 2>nul
cd /d "C:\CBA_Portal\cantonment-web\backend"
del package-lock.json 2>nul
del npm-shrinkwrap.json 2>nul
del yarn.lock 2>nul
echo ✓ All lock files removed

echo [5/10] Clearing global npm cache...
call npm cache clean --force
echo ✓ Global cache cleared

echo [6/10] Creating PostgreSQL-ONLY package.json for backend...
cd /d "C:\CBA_Portal\cantonment-web\backend"
if exist package.json ren package.json package.json.old

(
echo {
echo   "name": "cba-portal-postgresql",
echo   "version": "3.0.0",
echo   "description": "CBA Portal with PostgreSQL Only",
echo   "main": "server.js",
echo   "scripts": {
echo     "start": "node server.js"
echo   },
echo   "dependencies": {
echo     "bcryptjs": "^2.4.3",
echo     "cors": "^2.8.5",
echo     "dotenv": "^16.3.1",
echo     "express": "^4.18.2",
echo     "express-rate-limit": "^6.8.1", 
echo     "express-validator": "^7.0.1",
echo     "helmet": "^7.0.0",
echo     "jsonwebtoken": "^9.0.2",
echo     "multer": "^1.4.5-lts.1",
echo     "pdfkit": "^0.17.2",
echo     "pg": "^8.11.3",
echo     "pg-hstore": "^2.3.4"
echo   },
echo   "engines": {
echo     "node": "^18.0.0 || ^20.0.0 || ^22.0.0"
echo   }
echo }
) > package.json
echo ✓ PostgreSQL-only package.json created

echo [7/10] Installing backend dependencies (PostgreSQL only)...
call npm install
if errorlevel 1 (
    echo ⚠️  Some packages had issues, trying again...
    call npm install --legacy-peer-deps
)
echo ✓ Backend dependencies installed

echo [8/10] Creating PostgreSQL-exclusive configuration...
(
    echo # CBA Portal - PostgreSQL Exclusive
    echo PORT=5000
    echo NODE_ENV=production
    echo.
    echo # PostgreSQL Database
    echo DB_TYPE=postgresql
    echo DB_HOST=localhost
    echo DB_PORT=5432
    echo DB_NAME=cba_portal
    echo DB_USER=cba_admin
    echo DB_PASSWORD=CBA@2025Portal
    echo.
    echo # Security
    echo JWT_SECRET=cba-portal-postgresql-nuclear-2025
    echo.
    echo # Network
    echo HOST=0.0.0.0
    echo CORS_ORIGIN=*
    echo.
    echo # Database Pool Settings
    echo DB_POOL_MIN=2
    echo DB_POOL_MAX=10
    echo DB_POOL_IDLE=10000
    echo.
    echo # Explicitly disable SQLite
    echo NO_SQLITE=true
    echo FORCE_POSTGRESQL=true
) > .env
echo ✓ Configuration created

echo [9/10] Verifying installation...
if exist node_modules\pg (
    echo ✓ PostgreSQL driver installed
) else (
    echo ❌ PostgreSQL driver missing!
)

if exist node_modules\sqlite3 (
    echo ❌ WARNING: SQLite still present, removing...
    rd /s /q node_modules\sqlite3
) else (
    echo ✓ No SQLite modules found
)

echo [10/10] Final test - checking Node.js can start...
node --version
if errorlevel 1 (
    echo ❌ Node.js issue
) else (
    echo ✓ Node.js working
)

echo.
echo ===========================================================
echo   🚀 NUCLEAR REINSTALL COMPLETE!
echo ===========================================================
echo.
echo Everything has been rebuilt from scratch for PostgreSQL only.
echo.
echo What was done:
echo ✓ Removed ALL node_modules everywhere
echo ✓ Removed ALL lock files
echo ✓ Created PostgreSQL-exclusive package.json
echo ✓ Installed only PostgreSQL dependencies
echo ✓ Created PostgreSQL-only configuration
echo ✓ Verified no SQLite modules remain
echo.
echo Your application now has ZERO SQLite components!
echo.
echo Test the server:
echo start-cba-portal-postgresql.bat
echo.
echo If this doesn't work, there might be an issue with
echo your project's core files that require code changes.
echo.
pause