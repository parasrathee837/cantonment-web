@echo off
REM Live monitoring for CBA Portal database - Safe Version
REM Uses only columns that definitely exist

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo ===========================================
echo LIVE DATABASE MONITOR - CBA PORTAL (SAFE)
echo Monitors using existing columns only
echo ===========================================
echo Press Ctrl+C to stop monitoring
echo ===========================================

:loop
cls
echo ===========================================
echo CBA PORTAL DATABASE - %date% %time%
echo ===========================================
echo.

echo BASIC STATISTICS:
echo -----------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Users: ' || COUNT(*) FROM users;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Admissions: ' || COUNT(*) FROM admissions;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Designations: ' || COUNT(*) FROM designations;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Nationalities: ' || COUNT(*) FROM nationalities;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'PS Verifications: ' || COUNT(*) FROM ps_verifications;" 2>nul

REM Check if new tables exist and show counts
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'User Profiles: ' || COUNT(*) FROM user_complete_profile;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Attendance Records: ' || COUNT(*) FROM attendance;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Payslips: ' || COUNT(*) FROM payslips;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Leave Applications: ' || COUNT(*) FROM leave_applications;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Files: ' || COUNT(*) FROM files;" 2>nul
echo.

echo RECENT ACTIVITY (Last 15 minutes):
echo ----------------------------------
echo [BASIC TABLES:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- New user: ' || username || ' at ' || created_at FROM users WHERE created_at > NOW() - INTERVAL '15 minutes';" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- User updated: ' || username || ' at ' || updated_at FROM users WHERE updated_at > NOW() - INTERVAL '15 minutes' AND updated_at != created_at;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- New admission (ID: ' || id || ') at ' || created_at FROM admissions WHERE created_at > NOW() - INTERVAL '15 minutes';" 2>nul

echo [EXTENDED TABLES (if they exist):]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Profile created: ' || username || ' at ' || created_at FROM user_complete_profile WHERE created_at > NOW() - INTERVAL '15 minutes';" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Attendance marked: User ' || user_id || ' (' || status || ')' FROM attendance WHERE created_at > NOW() - INTERVAL '15 minutes';" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Leave applied: User ' || user_id || ' (' || leave_type || ')' FROM leave_applications WHERE created_at > NOW() - INTERVAL '15 minutes';" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- Payslip generated: User ' || user_id || ' (' || month || '/' || year || ')' FROM payslips WHERE generated_at > NOW() - INTERVAL '15 minutes';" 2>nul

echo.
echo TABLE AVAILABILITY CHECK:
echo -------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT COUNT(*) || ' total tables available' FROM information_schema.tables WHERE table_schema = 'public';"

echo Tables that exist:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- ' || table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"

echo.
echo Refreshing in 15 seconds...
echo (This version is safe and won't show column errors)
timeout /t 15 >nul
goto loop