@echo off
REM Live monitoring of database changes

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=postgres

echo ===========================================
echo LIVE DATABASE MONITORING
echo ===========================================
echo Press Ctrl+C to stop monitoring
echo ===========================================
echo.

:loop
cls
echo ===========================================
echo DATABASE UPDATE MONITOR - %date% %time%
echo ===========================================
echo.

echo RECENT CHANGES (Last 60 seconds):
echo ---------------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'USER: ' || username || ' updated at ' || updated_at FROM users WHERE updated_at > NOW() - INTERVAL '60 seconds';"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'ATTENDANCE: ' || u.username || ' marked ' || a.status || ' at ' || a.created_at FROM attendance a JOIN users u ON a.user_id = u.id WHERE a.created_at > NOW() - INTERVAL '60 seconds';"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'LOGIN: ' || username || ' at ' || last_login FROM users WHERE last_login > NOW() - INTERVAL '60 seconds';"
echo.

echo CURRENT STATISTICS:
echo -------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total Users: ' || COUNT(*) FROM users;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Today Attendance: ' || COUNT(*) FROM attendance WHERE DATE(date) = CURRENT_DATE;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Active Sessions: ' || COUNT(*) FROM users WHERE last_login > NOW() - INTERVAL '30 minutes';"

timeout /t 5 >nul
goto loop