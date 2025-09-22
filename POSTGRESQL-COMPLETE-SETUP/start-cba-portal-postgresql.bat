@echo off
color 0A
cls
echo ===========================================================
echo     CBA PORTAL - POSTGRESQL EDITION - STARTING UP
echo ===========================================================
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

:: Check PostgreSQL service
echo Checking PostgreSQL service...
sc query postgresql-x64-15 >nul 2>&1
if errorlevel 1 (
    sc query postgresql-x64-16 >nul 2>&1
    if errorlevel 1 (
        echo WARNING: PostgreSQL service not found!
        echo Please ensure PostgreSQL is installed and running.
        echo.
        pause
    ) else (
        set PGSVC=postgresql-x64-16
    )
) else (
    set PGSVC=postgresql-x64-15
)

:: Check if PostgreSQL service is running
if defined PGSVC (
    sc query %PGSVC% | find "RUNNING" >nul
    if errorlevel 1 (
        echo PostgreSQL service is not running. Starting...
        net start %PGSVC%
        timeout /t 3 /nobreak >nul
    )
)

:: Get computer's IP address
echo Finding your network address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        set IP_ADDRESS=%%b
        goto :found
    )
)
:found

:: Remove leading spaces
set IP_ADDRESS=%IP_ADDRESS: =%

cls
echo ===========================================================
echo     CBA PORTAL - POSTGRESQL EDITION - RUNNING
echo ===========================================================
echo.
echo    ✓ Database: PostgreSQL (Professional Grade)
echo    ✓ Server Status: STARTING...
echo.
echo ===========================================================
echo    HOW TO ACCESS YOUR PORTAL:
echo ===========================================================
echo.
echo    From THIS computer:
echo    ► http://localhost:5000
echo.
echo    From OTHER computers on network:
echo    ► http://%IP_ADDRESS%:5000
echo.
echo ===========================================================
echo    DATABASE MANAGEMENT:
echo ===========================================================
echo    pgAdmin 4: Start Menu → pgAdmin 4
echo    Database: cba_portal
echo    Username: cba_admin
echo.
echo ===========================================================
echo    DEFAULT LOGIN:
echo ===========================================================
echo    Username: admin
echo    Password: admin123
echo.
echo ===========================================================
echo.
echo    ⚠  IMPORTANT: KEEP THIS WINDOW OPEN!
echo    The server runs as long as this window is open.
echo    To stop: Press Ctrl+C
echo.
echo ===========================================================
echo.

:: Navigate to backend directory
cd /d "C:\CBA_Portal\cantonment-web\backend"

:: Create or update .env file for PostgreSQL
echo Creating PostgreSQL configuration...
(
    echo # PostgreSQL Configuration
    echo DB_TYPE=postgresql
    echo DB_HOST=localhost
    echo DB_PORT=5432
    echo DB_NAME=cba_portal
    echo DB_USER=cba_admin
    echo DB_PASSWORD=CBA@2025Portal
    echo.
    echo # Server Configuration
    echo PORT=5000
    echo NODE_ENV=production
    echo HOST=0.0.0.0
    echo.
    echo # Security
    echo JWT_SECRET=cba-portal-postgresql-secret-2025
    echo.
    echo # Network Access
    echo CORS_ORIGIN=*
) > .env

echo Starting server...
echo.

:: Start the server with error handling
node server.js 2>&1

:: If we reach here, server has stopped
echo.
echo ===========================================================
echo    Server has stopped.
echo ===========================================================
echo.
pause