@echo off
REM Live monitoring for CBA Portal database - Complete Version
REM Monitors all tables in the system

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo ===========================================
echo LIVE DATABASE MONITOR - COMPLETE CBA PORTAL
echo ===========================================
echo Monitoring ALL tables in real-time
echo Press Ctrl+C to stop monitoring
echo ===========================================

:loop
cls
echo ===========================================
echo CBA PORTAL COMPLETE DATABASE - %date% %time%
echo ===========================================
echo.

echo USER MANAGEMENT STATISTICS:
echo ---------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Basic Users: ' || COUNT(*) FROM users WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Complete Profiles: ' || COUNT(*) FROM user_complete_profile WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_complete_profile');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Active Sessions: ' || COUNT(*) FROM user_sessions WHERE is_active = true AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_sessions');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Recent Logins (24h): ' || COUNT(*) FROM user_login_history WHERE login_time > NOW() - INTERVAL '24 hours' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_login_history');"
echo.

echo STAFF MANAGEMENT STATISTICS:
echo ----------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total Admissions: ' || COUNT(*) FROM admissions WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admissions');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Staff Personal Records: ' || COUNT(*) FROM staff_personal WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_personal');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Banking Details: ' || COUNT(*) FROM staff_banking WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_banking');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Staff Documents: ' || COUNT(*) FROM staff_documents WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_documents');"
echo.

echo ATTENDANCE SYSTEM:
echo ------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Today Attendance: ' || COUNT(*) FROM attendance WHERE DATE(date) = CURRENT_DATE AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Attendance Records: ' || COUNT(*) FROM attendance_records WHERE DATE(created_at) = CURRENT_DATE AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance_records');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total Holidays: ' || COUNT(*) FROM holidays WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'holidays');"
echo.

echo LEAVE MANAGEMENT:
echo -----------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Leave Applications: ' || COUNT(*) FROM leave_applications WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'leave_applications');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Pending Leaves: ' || COUNT(*) FROM leave_applications WHERE status = 'pending' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'leave_applications');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Leave Types: ' || COUNT(*) FROM leave_types WHERE is_active = true AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'leave_types');"
echo.

echo PAYROLL SYSTEM:
echo ---------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total Payslips: ' || COUNT(*) FROM payslips WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payslips');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'This Month Payslips: ' || COUNT(*) FROM payslips WHERE month = EXTRACT(MONTH FROM CURRENT_DATE) AND year = EXTRACT(YEAR FROM CURRENT_DATE) AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payslips');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'PS Verifications: ' || COUNT(*) FROM ps_verifications WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ps_verifications');"
echo.

echo CODE MANAGEMENT:
echo ----------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Function Codes: ' || COUNT(*) FROM codes WHERE code_type = 'function' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'codes');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Object Codes: ' || COUNT(*) FROM codes WHERE code_type = 'object' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'codes');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total Designations: ' || COUNT(*) FROM designations WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'designations');"
echo.

echo SYSTEM & FILES:
echo ---------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Uploaded Files: ' || COUNT(*) FROM files WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'files');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Documents: ' || COUNT(*) FROM documents WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'documents');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Unread Notifications: ' || COUNT(*) FROM notifications WHERE is_read = false AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Audit Log Entries: ' || COUNT(*) FROM audit_logs WHERE DATE(created_at) = CURRENT_DATE AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs');"
echo.

echo RECENT CHANGES (Last 5 minutes):
echo --------------------------------
echo [USER ACTIVITY:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- New user: ' || username || ' created at ' || created_at FROM users WHERE created_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Profile updated: ' || full_name || ' at ' || updated_at FROM user_complete_profile WHERE updated_at > NOW() - INTERVAL '5 minutes' AND updated_at != created_at AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_complete_profile');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Login: ' || (SELECT username FROM users WHERE id = uh.user_id) || ' at ' || login_time FROM user_login_history uh WHERE login_time > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_login_history');"

echo [STAFF ACTIVITY:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- New admission: ' || staff_name || ' (' || staff_id || ')' FROM admissions WHERE created_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admissions');"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Staff personal added: ' || full_name || ' (' || staff_id || ')' FROM staff_personal WHERE created_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_personal');"

echo [ATTENDANCE ACTIVITY:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Attendance marked: ' || staff_id || ' - ' || status || ' at ' || created_at FROM attendance WHERE created_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance');"

echo [LEAVE ACTIVITY:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Leave applied: ' || staff_id || ' (' || leave_type || ') from ' || start_date || ' to ' || end_date FROM leave_applications WHERE created_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'leave_applications');"

echo [PAYROLL ACTIVITY:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Payslip generated: ' || staff_id || ' for ' || month || '/' || year FROM payslips WHERE generated_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payslips');"

echo [FILE ACTIVITY:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- File uploaded: ' || file_name || ' by user ' || user_id FROM files WHERE uploaded_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'files');"

echo [SYSTEM ACTIVITY:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- ' || action || ': ' || entity_type || ' (ID: ' || entity_id || ') by user ' || user_id FROM audit_logs WHERE created_at > NOW() - INTERVAL '5 minutes' AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs');"

echo.
echo ===========================================
echo Auto-refreshing in 15 seconds...
echo Press Ctrl+C to stop monitoring
echo ===========================================
timeout /t 15 >nul
goto loop