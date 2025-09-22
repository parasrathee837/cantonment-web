@echo off
color 0F
echo ===========================================================
echo    CBA PORTAL - POSTGRESQL INSTALLATION CHECKER
echo ===========================================================
echo.
echo Checking your PostgreSQL installation...
echo.

set ERRORS=0

:: Check Node.js
echo [1/6] Checking Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo    ❌ Node.js NOT INSTALLED
    set /a ERRORS+=1
) else (
    for /f "tokens=*" %%i in ('node --version') do echo    ✓ Node.js installed: %%i
)

:: Check PostgreSQL
echo [2/6] Checking PostgreSQL...
psql --version >nul 2>&1
if errorlevel 1 (
    echo    ❌ PostgreSQL NOT INSTALLED or not in PATH
    set /a ERRORS+=1
) else (
    for /f "tokens=*" %%i in ('psql --version') do echo    ✓ PostgreSQL installed: %%i
)

:: Check PostgreSQL service
echo [3/6] Checking PostgreSQL service...
sc query postgresql-x64-15 >nul 2>&1
if errorlevel 1 (
    sc query postgresql-x64-16 >nul 2>&1
    if errorlevel 1 (
        echo    ❌ PostgreSQL service NOT FOUND
        set /a ERRORS+=1
    ) else (
        echo    ✓ PostgreSQL 16 service found
        sc query postgresql-x64-16 | find "RUNNING" >nul
        if errorlevel 1 (
            echo    ⚠  PostgreSQL 16 service not running
        ) else (
            echo    ✓ PostgreSQL 16 service running
        )
    )
) else (
    echo    ✓ PostgreSQL 15 service found
    sc query postgresql-x64-15 | find "RUNNING" >nul
    if errorlevel 1 (
        echo    ⚠  PostgreSQL 15 service not running
    ) else (
        echo    ✓ PostgreSQL 15 service running
    )
)

:: Check project folder
echo [4/6] Checking project folder...
if exist "C:\CBA_Portal\cantonment-web" (
    echo    ✓ Project folder exists
) else (
    echo    ❌ Project folder NOT FOUND at C:\CBA_Portal\cantonment-web
    set /a ERRORS+=1
)

:: Check backend files
echo [5/6] Checking application files...
if exist "C:\CBA_Portal\cantonment-web\backend\server.js" (
    echo    ✓ Server files found
) else (
    echo    ❌ Server files NOT FOUND
    set /a ERRORS+=1
)

if exist "C:\CBA_Portal\cantonment-web\backend\node_modules" (
    echo    ✓ Application installed
) else (
    echo    ❌ Application NOT INSTALLED (run install-dependencies.bat)
    set /a ERRORS+=1
)

:: Check PostgreSQL configuration
if exist "C:\CBA_Portal\cantonment-web\backend\.env" (
    findstr /i "postgresql" "C:\CBA_Portal\cantonment-web\backend\.env" >nul
    if errorlevel 1 (
        echo    ⚠  Configuration file exists but not set for PostgreSQL
    ) else (
        echo    ✓ PostgreSQL configuration found
    )
) else (
    echo    ❌ Configuration file NOT FOUND
    set /a ERRORS+=1
)

:: Check database connection
echo [6/6] Checking database connection...
set PGPASSWORD=CBA@2025Portal
echo SELECT 'Connection test successful' as result; | psql -U cba_admin -d cba_portal -h localhost >nul 2>&1
if errorlevel 1 (
    echo    ❌ Database connection FAILED
    echo       - Check if PostgreSQL service is running
    echo       - Check if database 'cba_portal' exists
    echo       - Verify credentials: cba_admin / CBA@2025Portal
    set /a ERRORS+=1
) else (
    echo    ✓ Database connection successful
)

:: Check firewall
echo.
echo [BONUS] Checking network configuration...
netsh advfirewall firewall show rule name="CBA Portal Server" >nul 2>&1
if errorlevel 1 (
    echo    ⚠  Firewall not configured (run configure-network.bat as admin)
) else (
    echo    ✓ Firewall configured
)

echo.
echo ===========================================================
if %ERRORS%==0 (
    echo    ✓ ALL CHECKS PASSED! 
    echo    Your CBA Portal with PostgreSQL is ready to use.
    echo.
    echo    Next step: Run "start-cba-portal-postgresql.bat"
    echo.
    echo    Database management:
    echo    - pgAdmin 4: Start Menu → pgAdmin 4
    echo    - Command line: view-database-postgresql.bat
    echo    - Backups: backup-database.bat
) else (
    echo    ⚠  SOME ISSUES FOUND (%ERRORS% errors)
    echo    Please fix the errors marked with ❌ above
    echo.
    echo    Installation steps:
    echo    1. Run install-node.bat
    echo    2. Run install-postgresql.bat
    echo    3. Run setup-project-folder.bat
    echo    4. Run create-database.bat
    echo    5. Run install-dependencies.bat
    echo    6. Run configure-network.bat as administrator
)
echo ===========================================================
echo.

:: Show database info if connection works
if %ERRORS%==0 (
    echo PostgreSQL Database Information:
    echo --------------------------------
    echo Server: localhost:5432
    echo Database: cba_portal
    echo Username: cba_admin
    echo Password: CBA@2025Portal
    echo.
    echo Management Tools:
    echo - pgAdmin 4 (GUI): Start Menu → pgAdmin 4
    echo - Command Line: psql -U cba_admin -d cba_portal
    echo - Web Access: http://localhost:5000
    echo.
)

pause