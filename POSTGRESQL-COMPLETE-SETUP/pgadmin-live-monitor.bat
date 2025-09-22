@echo off
REM Live monitoring specifically for pgAdmin4 verification
REM Shows real-time data changes that you can verify in pgAdmin4

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=cba_admin
set PGPASSWORD=admin123

echo ===========================================
echo PGADMIN4 LIVE DATA MONITOR
echo ===========================================
echo This monitor shows EXACTLY what you should see in pgAdmin4
echo Refresh your pgAdmin4 tables to see the same data!
echo ===========================================
echo Press Ctrl+C to stop monitoring
echo ===========================================

:loop
cls
echo ===========================================
echo PGADMIN4 LIVE MONITOR - %date% %time%
echo ===========================================
echo Refresh your pgAdmin4 to see these exact numbers!
echo ===========================================
echo.

echo 📊 TABLE RECORD COUNTS (Visible in pgAdmin4):
echo ============================================

REM Show counts for all major tables
echo [USERS MANAGEMENT]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Users table: ' || COUNT(*) || ' records' FROM users;" 2>nul || echo "  Users table: Error accessing"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  User profiles: ' || COUNT(*) || ' records' FROM user_complete_profile;" 2>nul || echo "  User profiles: Error accessing"

echo.
echo [STAFF MANAGEMENT]  
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Admissions: ' || COUNT(*) || ' records' FROM admissions;" 2>nul || echo "  Admissions: Error accessing"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Staff personal: ' || COUNT(*) || ' records' FROM staff_personal;" 2>nul || echo "  Staff personal: Error accessing"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Staff banking: ' || COUNT(*) || ' records' FROM staff_banking;" 2>nul || echo "  Staff banking: Error accessing"

echo.
echo [ATTENDANCE SYSTEM]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Attendance: ' || COUNT(*) || ' records' FROM attendance;" 2>nul || echo "  Attendance: Error accessing"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Today attendance: ' || COUNT(*) || ' records' FROM attendance WHERE DATE(date) = CURRENT_DATE;" 2>nul || echo "  Today attendance: Error accessing"

echo.
echo [PAYROLL SYSTEM]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Payslips: ' || COUNT(*) || ' records' FROM payslips;" 2>nul || echo "  Payslips: Error accessing"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  PS Verifications: ' || COUNT(*) || ' records' FROM ps_verifications;" 2>nul || echo "  PS Verifications: Error accessing"

echo.
echo [LEAVE MANAGEMENT]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Leave applications: ' || COUNT(*) || ' records' FROM leave_applications;" 2>nul || echo "  Leave applications: Error accessing"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Leave types: ' || COUNT(*) || ' records' FROM leave_types;" 2>nul || echo "  Leave types: Error accessing"

echo.
echo [SYSTEM DATA]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Designations: ' || COUNT(*) || ' records' FROM designations;" 2>nul || echo "  Designations: Error accessing"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Nationalities: ' || COUNT(*) || ' records' FROM nationalities;" 2>nul || echo "  Nationalities: Error accessing"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '  Function/Object codes: ' || COUNT(*) || ' records' FROM codes;" 2>nul || echo "  Codes: Error accessing"
psql -h %PGHOST% -p %PGDATABASE% -p %PGPORT% -U %PGUSER% -t -c "SELECT '  Uploaded files: ' || COUNT(*) || ' records' FROM files;" 2>nul || echo "  Files: Error accessing"

echo.
echo 🔄 RECENT CHANGES (Last 10 minutes):
echo ===================================
echo [NEW DATA ENTRIES]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '↗ New user: ' || username || ' (' || role || ') at ' || created_at FROM users WHERE created_at > NOW() - INTERVAL '10 minutes' ORDER BY created_at DESC;" 2>nul

psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '↗ New admission: ID=' || id || ' at ' || created_at FROM admissions WHERE created_at > NOW() - INTERVAL '10 minutes' ORDER BY created_at DESC;" 2>nul

psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '↗ New attendance: User=' || user_id || ' Status=' || status || ' at ' || created_at FROM attendance WHERE created_at > NOW() - INTERVAL '10 minutes' ORDER BY created_at DESC;" 2>nul

psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '↗ New payslip: User=' || user_id || ' (' || month || '/' || year || ') at ' || generated_at FROM payslips WHERE generated_at > NOW() - INTERVAL '10 minutes' ORDER BY generated_at DESC;" 2>nul

psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '↗ File uploaded: ' || filename || ' at ' || uploaded_at FROM files WHERE uploaded_at > NOW() - INTERVAL '10 minutes' ORDER BY uploaded_at DESC;" 2>nul

echo.
echo 📋 LATEST RECORDS (Most recent entries):
echo ======================================
echo [LAST 3 USERS]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, created_at FROM users ORDER BY created_at DESC LIMIT 3;" 2>nul

echo.
echo [LAST 3 ADMISSIONS]  
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, COALESCE(staff_name, 'No name') as name, created_at FROM admissions ORDER BY created_at DESC LIMIT 3;" 2>nul

echo.
echo 💡 TO VERIFY IN PGADMIN4:
echo =========================
echo 1. Open pgAdmin4
echo 2. Navigate to: Servers → CBA Portal → Databases → cba_portal → Schemas → public → Tables
echo 3. Right-click any table → "View/Edit Data" → "All Rows"
echo 4. The data shown above should match exactly!
echo 5. Press F5 in pgAdmin4 to refresh if numbers don't match
echo.

echo Next refresh in 15 seconds...
echo (The counts above should be visible in your pgAdmin4 tables)
timeout /t 15 >nul
goto loop