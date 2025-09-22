@echo off
color 0A
cls
echo ===========================================================
echo   CBA PORTAL - POSTGRESQL EDITION - COMPLETE SETUP
echo ===========================================================
echo.
echo This will install EVERYTHING automatically with PostgreSQL!
echo.
echo What will be installed:
echo ✓ Node.js (JavaScript runtime)
echo ✓ PostgreSQL (Professional database)
echo ✓ CBA Portal application
echo ✓ Network configuration
echo ✓ All dependencies
echo.
echo Time required: 20-30 minutes
echo.
echo Press any key to start or Ctrl+C to cancel...
pause >nul

:: Step 1: Install Node.js
cls
echo ===========================================================
echo    STEP 1/6: INSTALLING NODE.JS
echo ===========================================================
call install-node.bat
if errorlevel 1 (
    echo Installation failed! Please check and try again.
    pause
    exit /b 1
)

:: Step 2: Install PostgreSQL
cls
echo ===========================================================
echo    STEP 2/6: INSTALLING POSTGRESQL
echo ===========================================================
echo.
echo ⚠️  IMPORTANT: You will be asked to set a password!
echo    Recommended password: CBA@2025Portal
echo    REMEMBER THIS PASSWORD!
echo.
pause
call install-postgresql.bat

:: Step 3: Setup folders
cls
echo ===========================================================
echo    STEP 3/6: SETTING UP PROJECT FOLDERS
echo ===========================================================
call setup-project-folder.bat

:: Check if user copied files
if not exist "C:\CBA_Portal\cantonment-web\backend\package.json" (
    echo.
    echo ===========================================================
    echo    ACTION REQUIRED!
    echo ===========================================================
    echo.
    echo Please copy your "cantonment-web" folder to:
    echo C:\CBA_Portal\
    echo.
    echo Then run this script again from STEP 4.
    echo.
    explorer "C:\CBA_Portal"
    pause
    exit /b 1
)

:: Step 4: Create database
cls
echo ===========================================================
echo    STEP 4/6: CREATING POSTGRESQL DATABASE
echo ===========================================================
call create-database.bat

:: Step 5: Install dependencies
cls
echo ===========================================================
echo    STEP 5/6: INSTALLING APPLICATION
echo ===========================================================
call install-dependencies.bat

:: Step 6: Configure network
cls
echo ===========================================================
echo    STEP 6/6: CONFIGURING NETWORK ACCESS
echo ===========================================================
echo.
echo ⚠  This step needs Administrator rights!
echo.
echo A new window will open asking for permission.
echo Please click "Yes" to allow.
echo.
pause
powershell -Command "Start-Process '%CD%\configure-network.bat' -Verb RunAs" 2>nul
if errorlevel 1 (
    echo Could not auto-elevate. Please run configure-network.bat manually as administrator.
)
echo.
echo Press any key after network configuration is complete...
pause >nul

:: Final verification
cls
echo ===========================================================
echo    FINAL VERIFICATION
echo ===========================================================

:: Check PostgreSQL service
echo Checking PostgreSQL service...
sc query postgresql-x64-15 >nul 2>&1 || sc query postgresql-x64-16 >nul 2>&1
if errorlevel 1 (
    echo ⚠️  PostgreSQL service not found
) else (
    echo ✓ PostgreSQL service available
)

:: Check database connection
echo Checking database connection...
set PGPASSWORD=CBA@2025Portal
echo SELECT 'Test' as result; | psql -U cba_admin -d cba_portal -h localhost >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Database connection issues
) else (
    echo ✓ Database connection working
)

:: Check application files
if exist "C:\CBA_Portal\cantonment-web\backend\node_modules" (
    echo ✓ Application installed
) else (
    echo ⚠️  Application installation incomplete
)

:: Create desktop shortcut
echo.
echo Creating desktop shortcuts...
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Start CBA Portal (PostgreSQL).lnk'); $Shortcut.TargetPath = '%CD%\start-cba-portal-postgresql.bat'; $Shortcut.WorkingDirectory = '%CD%'; $Shortcut.IconLocation = '%SystemRoot%\System32\shell32.dll,13'; $Shortcut.Save()"

powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\View Database (pgAdmin).lnk'); $Shortcut.TargetPath = '%CD%\view-database-postgresql.bat'; $Shortcut.WorkingDirectory = '%CD%'; $Shortcut.IconLocation = '%SystemRoot%\System32\shell32.dll,18'; $Shortcut.Save()"

echo ✓ Desktop shortcuts created!

echo.
echo ===========================================================
echo    🎉 POSTGRESQL SETUP COMPLETE! 🎉
echo ===========================================================
echo.
echo Your CBA Portal with PostgreSQL is ready!
echo.
echo To start your portal:
echo ✓ Double-click "Start CBA Portal (PostgreSQL)" on desktop
echo   OR
echo ✓ Run "start-cba-portal-postgresql.bat" from this folder
echo.
echo To manage database:
echo ✓ Double-click "View Database (pgAdmin)" on desktop
echo   OR
echo ✓ Start Menu → pgAdmin 4
echo.
echo Database credentials:
echo - Server: localhost:5432
echo - Database: cba_portal  
echo - Username: cba_admin
echo - Password: CBA@2025Portal
echo.
echo Thank you for choosing PostgreSQL for CBA Portal!
echo.
pause