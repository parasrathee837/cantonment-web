@echo off
REM Live monitoring for CBA Portal database - Enhanced Version

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo ===========================================
echo LIVE DATABASE MONITOR - CBA PORTAL
echo Enhanced monitoring with all tables
echo ===========================================
echo Press Ctrl+C to stop monitoring
echo ===========================================

:loop
cls
echo ===========================================
echo CBA PORTAL DATABASE - %date% %time%
echo ===========================================
echo.

echo CORE STATISTICS:
echo ----------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Users: ' || COUNT(*) FROM users WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Complete Profiles: ' || COUNT(*) FROM user_complete_profile WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_complete_profile');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Admissions: ' || COUNT(*) FROM admissions WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admissions');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Staff Personal: ' || COUNT(*) FROM staff_personal WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_personal');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Attendance Today: ' || COUNT(*) FROM attendance WHERE DATE(date) = CURRENT_DATE AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Payslips: ' || COUNT(*) FROM payslips WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payslips');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Leave Applications: ' || COUNT(*) FROM leave_applications WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'leave_applications');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Files Uploaded: ' || COUNT(*) FROM files WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'files');"
echo.

echo RECENT CHANGES (Last 5 minutes):
echo --------------------------------
echo [USER ACTIVITY:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- New user: ' || username || ' added at ' || created_at FROM users WHERE created_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Profile updated: ' || full_name || ' at ' || updated_at FROM user_complete_profile WHERE updated_at > NOW() - INTERVAL '5 minutes' AND updated_at != created_at AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_complete_profile');"

echo [STAFF ACTIVITY:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- New admission: ' || COALESCE(staff_name, 'Unknown') || ' (ID: ' || COALESCE(staff_id::text, id::text) || ')' FROM admissions WHERE created_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admissions');" 2>/dev/null || psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- New admission added (ID: ' || id || ')' FROM admissions WHERE created_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admissions');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Staff added: ' || full_name || ' (' || staff_id || ')' FROM staff_personal WHERE created_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_personal');" 2>/dev/null

echo [ATTENDANCE:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Attendance: User ' || user_id || ' - ' || status FROM attendance WHERE created_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance');" 2>/dev/null

echo [PAYROLL:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Payslip: User ' || user_id || ' for ' || month || '/' || year FROM payslips WHERE generated_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payslips');" 2>/dev/null

echo [SYSTEM:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- File uploaded: ' || filename FROM files WHERE uploaded_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'files');" 2>/dev/null || psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- File uploaded: ' || file_name FROM files WHERE uploaded_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'files');" 2>/dev/null

echo.
echo Refreshing in 15 seconds...
echo (Run watch-database-live-complete.bat for detailed monitoring)
timeout /t 15 >nul
goto loop