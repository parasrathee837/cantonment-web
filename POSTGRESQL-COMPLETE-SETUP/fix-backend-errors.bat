@echo off
echo ===========================================
echo CBA Portal - Fix Backend JSON Errors
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo The JSON parse error usually happens when:
echo 1. Backend returns HTML error page instead of JSON
echo 2. Database queries fail due to missing tables/columns
echo 3. Backend server crashes or isn't running
echo.

echo Checking common issues...
echo.

echo 1. Testing database connection...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'Database connection OK';" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Database connection is working
) else (
    echo [ERROR] Database connection failed
    echo This could be causing the JSON errors.
    pause
    exit /b 1
)

echo.
echo 2. Checking if required tables exist...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"

echo.
echo 3. Common missing tables that cause JSON errors:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_complete_profile') THEN '[OK] user_complete_profile exists' ELSE '[MISSING] user_complete_profile - THIS CAUSES ERRORS!' END;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance') THEN '[OK] attendance exists' ELSE '[MISSING] attendance table' END;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payslips') THEN '[OK] payslips exists' ELSE '[MISSING] payslips table' END;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'files') THEN '[OK] files exists' ELSE '[MISSING] files table' END;"

echo.
echo 4. Checking critical columns that cause errors...
echo Checking users table structure:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'users' ORDER BY ordinal_position;"

echo.
echo SOLUTION: If you see missing tables above, run:
echo create-all-missing-tables.bat
echo.
echo This will fix the database structure and stop the JSON errors.
echo.

echo 5. Backend Error Fixes:
echo.
echo If your backend is crashing, also check:
echo - Are all npm packages installed? (npm install)
echo - Is the .env file configured correctly?
echo - Are there any console errors when starting the server?
echo.

set /p fix="Do you want to run the complete database fix now? (Y/N): "
if /i "%fix%"=="Y" (
    echo.
    echo Running complete database setup...
    call create-all-missing-tables.bat
) else (
    echo.
    echo Please run create-all-missing-tables.bat manually to fix the issues.
)

echo.
pause