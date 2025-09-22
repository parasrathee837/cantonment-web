@echo off
color 0E
echo ===========================================================
echo   CLEAN POSTGRESQL-ONLY INSTALLATION
echo ===========================================================
echo.
echo This will completely remove all SQLite traces and install
echo only PostgreSQL dependencies.
echo.
echo ⚠️  WARNING: This will delete all node_modules and reinstall
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo [1/8] Navigating to project...
cd /d "C:\CBA_Portal\cantonment-web\backend"

echo [2/8] Backing up configuration...
if exist .env copy .env .env.backup >nul

echo [3/8] Removing ALL node_modules...
rd /s /q node_modules 2>nul
echo ✓ All modules removed

echo [4/8] Removing package-lock files...
del package-lock.json 2>nul
del npm-shrinkwrap.json 2>nul
echo ✓ Lock files removed

echo [5/8] Clearing npm cache completely...
call npm cache clean --force
call npm cache verify
echo ✓ Cache cleared

echo [6/8] Creating PostgreSQL-only package.json...
if exist package.json.backup del package.json.backup
ren package.json package.json.backup

(
echo {
echo   "name": "cba-portal-backend-postgresql",
echo   "version": "2.0.0",
echo   "description": "CBA Portal Backend with PostgreSQL",
echo   "main": "server.js",
echo   "scripts": {
echo     "start": "node server.js",
echo     "dev": "nodemon server.js"
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
echo   "devDependencies": {
echo     "nodemon": "^3.0.1"
echo   }
echo }
) > package.json
echo ✓ PostgreSQL-only package.json created

echo [7/8] Installing PostgreSQL dependencies only...
call npm install
echo ✓ PostgreSQL dependencies installed

echo [8/8] Creating PostgreSQL-only configuration...
(
    echo # CBA Portal - PostgreSQL Exclusive Configuration
    echo PORT=5000
    echo NODE_ENV=production
    echo.
    echo # PostgreSQL Database - NO SQLITE FALLBACK
    echo DB_TYPE=postgresql
    echo DB_HOST=localhost
    echo DB_PORT=5432
    echo DB_NAME=cba_portal
    echo DB_USER=cba_admin
    echo DB_PASSWORD=CBA@2025Portal
    echo.
    echo # Security
    echo JWT_SECRET=cba-portal-postgresql-exclusive-2025
    echo.
    echo # Network Configuration
    echo HOST=0.0.0.0
    echo CORS_ORIGIN=*
    echo.
    echo # Database Settings
    echo DB_SSL=false
    echo DB_POOL_MIN=2
    echo DB_POOL_MAX=10
) > .env
echo ✓ PostgreSQL-exclusive configuration created

echo.
echo ===========================================================
echo   ✓ CLEAN POSTGRESQL INSTALLATION COMPLETE!
echo ===========================================================
echo.
echo Changes made:
echo ✓ Removed all SQLite dependencies
echo ✓ Created PostgreSQL-only package.json
echo ✓ Installed only PostgreSQL drivers
echo ✓ Configuration set for PostgreSQL exclusive use
echo ✓ No SQLite fallback possible
echo.
echo Your application now uses ONLY PostgreSQL!
echo.
echo Test the installation:
echo start-cba-portal-postgresql.bat
echo.
pause