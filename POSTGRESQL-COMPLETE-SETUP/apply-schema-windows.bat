@echo off
echo ===========================================
echo CBA Portal - Complete Schema Setup
echo For Windows Installation
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Checking current database status...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT COUNT(*) || ' tables currently in database' FROM information_schema.tables WHERE table_schema = 'public';"
echo.

echo This will add all missing tables required for CBA Portal to work properly.
echo Your existing data (admin user) will be preserved.
echo.
set /p confirm="Do you want to continue? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo.
echo Creating backup...
set backup_file=backup_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.sql
set backup_file=%backup_file: =0%
pg_dump -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f %backup_file%
echo Backup saved to: %backup_file%

echo.
echo Applying complete schema...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -f complete-schema.sql

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to apply schema!
    echo Check the error messages above.
    pause
    exit /b 1
)

echo.
echo Verifying installation...
echo.
echo Tables in database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"

echo.
echo Checking key tables:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_complete_profile') THEN '[OK] user_complete_profile table created' ELSE '[ERROR] user_complete_profile table missing' END;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance') THEN '[OK] attendance table created' ELSE '[ERROR] attendance table missing' END;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payslips') THEN '[OK] payslips table created' ELSE '[ERROR] payslips table missing' END;"

echo.
echo Schema update complete!
echo.
echo IMPORTANT: The application uses 'user_complete_profile' table for detailed user data.
echo Your admin login is preserved and you can now create staff with full details.
echo.
echo To monitor database changes, use:
echo - quick-check-cba.bat
echo - monitor-cba-database.bat
echo.
pause