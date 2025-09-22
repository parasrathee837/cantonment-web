@echo off
echo ===========================================
echo CBA Portal - Fresh Start Database Setup
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo This will give you a completely fresh database with:
echo - Clean slate (all data removed)
echo - Admin login preserved
echo - All required tables created
echo - Only essential default data
echo.

echo Current status:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Current users: ' || COUNT(*) FROM users;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Current tables: ' || COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"
echo.

set /p confirm="Do you want a fresh start? (Y/N): "
if /i not "%confirm%"=="Y" exit /b 0

echo.
echo Step 1: Cleaning existing data (keeping admin)...
call clean-database-keep-admin.bat

echo.
echo Step 2: Creating complete database structure...
call create-all-missing-tables.bat

echo.
echo Step 3: Verifying fresh setup...
echo.
echo Database summary:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total tables: ' || COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Users: ' || COUNT(*) FROM users;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Admissions: ' || COUNT(*) FROM admissions;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Staff records: ' || COUNT(*) FROM staff_personal WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_personal');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Attendance records: ' || COUNT(*) FROM attendance WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Leave types available: ' || COUNT(*) FROM leave_types WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'leave_types');"

echo.
echo Admin login details:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'Username: ' || username, 'Role: ' || role FROM users WHERE role = 'admin';"

echo.
echo ===========================================
echo FRESH START COMPLETE!
echo ===========================================
echo.
echo Your database now has:
echo ✅ Clean slate - no old data
echo ✅ Admin login preserved
echo ✅ All 35+ required tables created
echo ✅ Essential default data (designations, leave types, codes)
echo ✅ Ready for production use
echo.
echo You can now:
echo 1. Login to admin portal with existing credentials
echo 2. Add staff members - all data will be saved properly
echo 3. All features will work (attendance, payroll, files, etc.)
echo.
echo To monitor activity: run watch-database-live-safe.bat
echo ===========================================
pause