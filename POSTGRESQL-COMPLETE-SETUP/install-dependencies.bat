@echo off
color 0A
echo ===========================================================
echo    INSTALLING CBA PORTAL - POSTGRESQL EDITION
echo ===========================================================
echo.
echo This will install all required components for PostgreSQL.
echo Please be patient - this takes 5-8 minutes.
echo.

:: Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed!
    echo Please run "install-node.bat" first.
    echo.
    pause
    exit /b 1
)

:: Check if PostgreSQL is available
psql --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: PostgreSQL is not installed or not in PATH!
    echo Please run "install-postgresql.bat" first.
    echo.
    pause
    exit /b 1
)

:: Check if project exists
if not exist "C:\CBA_Portal\cantonment-web\backend\package.json" (
    echo ERROR: Project files not found!
    echo Please run "setup-project-folder.bat" first.
    echo.
    pause
    exit /b 1
)

:: Navigate to backend directory
cd /d "C:\CBA_Portal\cantonment-web\backend"

echo Current directory: %CD%
echo.
echo ===========================================================
echo    Installing PostgreSQL components...
echo ===========================================================
echo.

:: Install dependencies with PostgreSQL support
echo Installing Node.js packages...
call npm install

:: Install PostgreSQL driver specifically
echo.
echo Installing PostgreSQL driver...
call npm install pg

:: Install additional PostgreSQL tools
echo.
echo Installing additional database tools...
call npm install pg-hstore

if errorlevel 1 (
    echo.
    echo ===========================================================
    echo    ⚠ WARNING: Some packages had errors
    echo ===========================================================
    echo This might still work. Let's continue...
    echo.
)

:: Create PostgreSQL .env file
echo.
echo Creating PostgreSQL configuration file...
(
    echo # CBA Portal - PostgreSQL Configuration
    echo PORT=5000
    echo NODE_ENV=production
    echo.
    echo # PostgreSQL Database Configuration
    echo DB_TYPE=postgresql
    echo DB_HOST=localhost
    echo DB_PORT=5432
    echo DB_NAME=cba_portal
    echo DB_USER=cba_admin
    echo DB_PASSWORD=CBA@2025Portal
    echo.
    echo # Security
    echo JWT_SECRET=cba-portal-postgresql-secret-2025
    echo.
    echo # Network Configuration
    echo HOST=0.0.0.0
    echo CORS_ORIGIN=*
) > .env
echo ✓ PostgreSQL configuration file created

:: Test database connection
echo.
echo Testing database connection...
set PGPASSWORD=CBA@2025Portal
echo SELECT 'Database connection test successful!' as status; | psql -U cba_admin -d cba_portal -h localhost >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Could not connect to database.
    echo    Make sure PostgreSQL is running and database is created.
    echo    Run "create-database.bat" if you haven't already.
) else (
    echo ✓ Database connection successful!
)

echo.
echo ===========================================================
echo    ✓ INSTALLATION COMPLETE!
echo ===========================================================
echo.
echo The CBA Portal application is now installed with PostgreSQL.
echo.
echo Configuration:
echo - Database: PostgreSQL
echo - Server: localhost:5432
echo - Database name: cba_portal
echo - Application port: 5000
echo.
echo Next step: Run "start-cba-portal-postgresql.bat" to start the server.
echo.
pause