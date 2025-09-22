@echo off
color 0A
echo ===========================================================
echo   OPEN POSTGRESQL DATABASE VIEWER
echo ===========================================================
echo.

:: Method 1: Try pgAdmin 4 (comes with PostgreSQL)
echo [1/3] Looking for pgAdmin 4...
if exist "C:\Program Files\pgAdmin 4\v6\runtime\pgAdmin4.exe" (
    echo ✓ Found pgAdmin 4 (v6)
    "C:\Program Files\pgAdmin 4\v6\runtime\pgAdmin4.exe"
    goto opened
)

if exist "C:\Program Files\pgAdmin 4\v7\runtime\pgAdmin4.exe" (
    echo ✓ Found pgAdmin 4 (v7)
    "C:\Program Files\pgAdmin 4\v7\runtime\pgAdmin4.exe"
    goto opened
)

if exist "C:\Program Files\pgAdmin 4\v8\runtime\pgAdmin4.exe" (
    echo ✓ Found pgAdmin 4 (v8)
    "C:\Program Files\pgAdmin 4\v8\runtime\pgAdmin4.exe"
    goto opened
)

:: Method 2: Try from Start Menu
echo [2/3] Trying to launch from Start Menu...
powershell -Command "Start-Process -FilePath 'shell:AppsFolder\pgAdmin4.pgAdmin4_pgadmin!App'" 2>nul
if not errorlevel 1 goto opened

:: Method 3: Command line access
echo [3/3] pgAdmin not found. Opening command line access...
echo.
echo ===========================================================
echo   COMMAND LINE DATABASE ACCESS
echo ===========================================================
echo.
echo pgAdmin 4 not found. You can:
echo.
echo 1. FIND pgAdmin 4:
echo    - Check Start Menu for "pgAdmin 4"
echo    - Or reinstall PostgreSQL (pgAdmin comes with it)
echo.
echo 2. USE COMMAND LINE:
echo    - Press any key to open command line access
echo.
echo 3. MANUAL CONNECTION INFO:
echo    Server: localhost
echo    Port: 5432
echo    Database: cba_portal
echo    Username: cba_admin
echo    Password: CBA@2025Portal
echo.
pause

:: Open command line PostgreSQL
echo.
echo Connecting to CBA Portal database...
echo.
echo Commands you can use:
echo \dt              - List all tables
echo \d table_name    - Describe a table
echo SELECT * FROM users;  - View users table
echo \q               - Quit
echo.
set PGPASSWORD=CBA@2025Portal
psql -U cba_admin -d cba_portal -h localhost

goto end

:opened
echo.
echo ✓ Database viewer opened!
echo.
echo ===========================================================
echo   HOW TO CONNECT IN pgAdmin:
echo ===========================================================
echo.
echo If this is your first time:
echo 1. Click "Add New Server" (or server icon)
echo 2. General tab:
echo    Name: CBA Portal
echo 3. Connection tab:
echo    Host: localhost
echo    Port: 5432
echo    Database: cba_portal
echo    Username: cba_admin
echo    Password: CBA@2025Portal
echo 4. Click Save
echo.
echo Then you can browse:
echo - Tables: users, admissions, designations, etc.
echo - Data: Click on tables to see data
echo - Query: Use Query Tool for custom SQL
echo.

:end
echo.
echo ===========================================================
echo   DATABASE TABLES IN CBA PORTAL:
echo ===========================================================
echo.
echo Key tables to check:
echo ✓ users           - Login accounts
echo ✓ admissions      - Staff/member records  
echo ✓ designations    - Job titles
echo ✓ user_sessions   - Active logins
echo ✓ login_attempts  - Security logs
echo ✓ ps_verifications - Payroll verifications
echo.
pause