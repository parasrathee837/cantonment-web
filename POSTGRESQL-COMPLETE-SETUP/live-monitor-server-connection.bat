@echo off
REM Live monitoring using SAME connection as your running server
REM Connects exactly like your CBA Portal server does

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo ===========================================
echo LIVE MONITOR - SERVER CONNECTION
echo ===========================================
echo Using SAME credentials as your running server:
echo Database: cba_portal@localhost:5432
echo User: postgres (same as server)
echo ===========================================
echo Press Ctrl+C to stop monitoring
echo ===========================================

:loop
cls
echo ===========================================
echo LIVE DATABASE MONITOR - %date% %time%
echo ===========================================
echo Monitoring SAME database your server uses
echo ===========================================
echo.

echo 📊 CURRENT DATA (What your server sees):
echo ========================================

echo [USER MANAGEMENT]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Users: ' || COUNT(*) || ' records' FROM users;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'User Profiles: ' || COUNT(*) || ' records' FROM user_complete_profile;" 2>nul

echo.
echo [STAFF DATA]  
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Admissions: ' || COUNT(*) || ' records' FROM admissions;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Designations: ' || COUNT(*) || ' records' FROM designations;" 2>nul

echo.
echo [ACTIVITY DATA]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Attendance Records: ' || COUNT(*) || ' records' FROM attendance;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Payslips: ' || COUNT(*) || ' records' FROM payslips;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Leave Applications: ' || COUNT(*) || ' records' FROM leave_applications;" 2>nul

echo.
echo 🔄 RECENT ACTIVITY (Last 10 minutes):
echo ====================================
echo [NEW ENTRIES FROM YOUR APPLICATION]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ User added: ' || username || ' (' || role || ') at ' || created_at FROM users WHERE created_at > NOW() - INTERVAL '10 minutes' ORDER BY created_at DESC LIMIT 5;" 2>nul

psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ Staff added: ' || COALESCE(staff_name, 'ID=' || id::text) || ' at ' || created_at FROM admissions WHERE created_at > NOW() - INTERVAL '10 minutes' ORDER BY created_at DESC LIMIT 5;" 2>nul

psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ Attendance: User ' || user_id || ' (' || status || ') at ' || created_at FROM attendance WHERE created_at > NOW() - INTERVAL '10 minutes' ORDER BY created_at DESC LIMIT 5;" 2>nul

psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ Payslip: User ' || user_id || ' (' || month || '/' || year || ') at ' || generated_at FROM payslips WHERE generated_at > NOW() - INTERVAL '10 minutes' ORDER BY generated_at DESC LIMIT 5;" 2>nul

echo.
echo 📋 LATEST DATA (Most recent records):
echo ===================================
echo [RECENT USERS]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'ID: ' || id || ' | ' || username || ' | ' || role || ' | ' || created_at FROM users ORDER BY created_at DESC LIMIT 3;" 2>nul

echo.
echo [RECENT STAFF]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'ID: ' || id || ' | ' || COALESCE(staff_name, 'No name') || ' | ' || created_at FROM admissions ORDER BY created_at DESC LIMIT 3;" 2>nul

echo.
echo 💡 PGADMIN4 CONNECTION INFO:
echo ===========================
echo To see this same data in pgAdmin4, connect with:
echo Host: localhost
echo Port: 5432
echo Database: cba_portal  
echo Username: postgres
echo Password: CBA@2025Portal
echo.
echo Then navigate to: Tables → [table_name] → View/Edit Data → All Rows
echo The counts shown above should match pgAdmin4 exactly!
echo.

echo 🔄 AUTO-REFRESH: This monitor updates every 15 seconds
echo 📱 TEST: Add data through your web app at http://localhost:5000
echo 👀 VERIFY: Watch new records appear here AND in pgAdmin4
echo.

echo Refreshing in 15 seconds...
timeout /t 15 >nul
goto loop