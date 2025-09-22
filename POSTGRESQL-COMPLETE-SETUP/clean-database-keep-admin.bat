@echo off
echo ===========================================
echo CBA Portal - Clean Database (Keep Admin Only)
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo WARNING: This will delete ALL data from the database
echo except the admin login credentials.
echo.
echo Current database contents:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Users: ' || COUNT(*) FROM users;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Admissions: ' || COUNT(*) FROM admissions;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total Tables: ' || COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"
echo.

echo The admin user will be preserved:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT username, role, created_at FROM users WHERE role = 'admin';"
echo.

set /p confirm="Are you sure you want to clean the database? Type 'YES' to confirm: "
if not "%confirm%"=="YES" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo.
echo Creating backup before cleaning...
set backup_file=backup_before_clean_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.sql
set backup_file=%backup_file: =0%
pg_dump -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f %backup_file%
echo Backup saved to: %backup_file%

echo.
echo Storing admin credentials...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "CREATE TEMP TABLE temp_admin AS SELECT * FROM users WHERE role = 'admin';"

echo.
echo Cleaning all data from database...

REM Create cleanup script
(
echo -- CBA Portal Database Cleanup Script
echo -- Preserves only admin credentials
echo.
echo -- Disable foreign key checks temporarily
echo SET session_replication_role = replica;
echo.
echo -- Clear all data from existing tables
echo TRUNCATE TABLE users CASCADE;
echo TRUNCATE TABLE admissions CASCADE;
echo TRUNCATE TABLE designations CASCADE;
echo TRUNCATE TABLE nationalities CASCADE;
echo TRUNCATE TABLE ps_verifications CASCADE;
echo.
echo -- Clear additional tables if they exist
echo TRUNCATE TABLE user_complete_profile CASCADE;
echo TRUNCATE TABLE user_profiles CASCADE;
echo TRUNCATE TABLE user_sessions CASCADE;
echo TRUNCATE TABLE user_activity CASCADE;
echo TRUNCATE TABLE login_attempts CASCADE;
echo TRUNCATE TABLE user_login_history CASCADE;
echo TRUNCATE TABLE staff_personal CASCADE;
echo TRUNCATE TABLE staff_banking CASCADE;
echo TRUNCATE TABLE staff_documents CASCADE;
echo TRUNCATE TABLE staff_salary CASCADE;
echo TRUNCATE TABLE staff_deductions CASCADE;
echo TRUNCATE TABLE staff_deductions_comprehensive CASCADE;
echo TRUNCATE TABLE attendance CASCADE;
echo TRUNCATE TABLE attendance_records CASCADE;
echo TRUNCATE TABLE daily_attendance CASCADE;
echo TRUNCATE TABLE holidays CASCADE;
echo TRUNCATE TABLE leaves CASCADE;
echo TRUNCATE TABLE leave_applications CASCADE;
echo TRUNCATE TABLE leave_types CASCADE;
echo TRUNCATE TABLE payslips CASCADE;
echo TRUNCATE TABLE codes CASCADE;
echo TRUNCATE TABLE function_codes CASCADE;
echo TRUNCATE TABLE object_codes CASCADE;
echo TRUNCATE TABLE files CASCADE;
echo TRUNCATE TABLE documents CASCADE;
echo TRUNCATE TABLE notifications CASCADE;
echo TRUNCATE TABLE audit_logs CASCADE;
echo TRUNCATE TABLE settings CASCADE;
echo TRUNCATE TABLE system_errors CASCADE;
echo TRUNCATE TABLE admin_dashboard_summary CASCADE;
echo TRUNCATE TABLE admin_actions CASCADE;
echo TRUNCATE TABLE admin_settings CASCADE;
echo.
echo -- Re-enable foreign key checks
echo SET session_replication_role = DEFAULT;
echo.
echo -- Restore admin user
echo INSERT INTO users ^(username, password, role, created_at, updated_at^)
echo SELECT username, password, role, created_at, updated_at FROM temp_admin;
echo.
echo -- Reset sequences to start from 2 ^(after admin user^)
echo SELECT setval^('users_id_seq', 1^);
echo SELECT setval^('admissions_id_seq', 1^);
echo SELECT setval^('designations_id_seq', 1^);
echo SELECT setval^('nationalities_id_seq', 1^);
echo SELECT setval^('ps_verifications_id_seq', 1^);
echo.
echo -- Insert essential default data
echo INSERT INTO designations ^(id, name, code^) VALUES 
echo ^(1, 'Administrator', 'ADMIN'^),
echo ^(2, 'Manager', 'MGR'^),
echo ^(3, 'Officer', 'OFF'^),
echo ^(4, 'Clerk', 'CLK'^),
echo ^(5, 'Assistant', 'AST'^)
echo ON CONFLICT DO NOTHING;
echo.
echo INSERT INTO nationalities ^(id, name, code^) VALUES 
echo ^(1, 'Indian', 'IN'^),
echo ^(2, 'Others', 'OTH'^)
echo ON CONFLICT DO NOTHING;
echo.
echo -- Add essential codes if codes table exists
echo INSERT INTO codes ^(code_type, code, description^) VALUES 
echo ^('function', 'ADM', 'Administration'^),
echo ^('function', 'FIN', 'Finance'^),
echo ^('function', 'HR', 'Human Resources'^),
echo ^('object', 'SAL', 'Salary'^),
echo ^('object', 'BEN', 'Benefits'^),
echo ^('object', 'TRV', 'Travel'^)
echo ON CONFLICT DO NOTHING;
echo.
echo -- Add default leave types if table exists
echo INSERT INTO leave_types ^(name, code, max_days_per_year^) VALUES 
echo ^('Casual Leave', 'CL', 12^),
echo ^('Sick Leave', 'SL', 12^),
echo ^('Earned Leave', 'EL', 30^)
echo ON CONFLICT DO NOTHING;
echo.
echo SELECT 'Database cleaned successfully. Admin user preserved.' as status;
) > temp_cleanup.sql

echo Executing cleanup...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -f temp_cleanup.sql

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS! Database cleaned successfully.
    del temp_cleanup.sql
    echo.
    echo Verifying results...
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Users remaining: ' || COUNT(*) FROM users;"
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Admissions remaining: ' || COUNT(*) FROM admissions;"
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Designations: ' || COUNT(*) FROM designations;"
    echo.
    echo Admin user preserved:
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT username, role FROM users;"
    echo.
    echo Database is now clean with only essential data.
    echo You can login with your admin credentials and start fresh.
) else (
    echo.
    echo ERROR: Failed to clean database!
    echo Check temp_cleanup.sql for issues.
)

echo.
pause