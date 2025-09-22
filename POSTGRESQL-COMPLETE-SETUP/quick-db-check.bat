@echo off
REM Quick database check - Shows latest changes

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=postgres

echo ===========================================
echo QUICK DATABASE UPDATE CHECK
echo ===========================================
echo.
echo Checking latest database changes...
echo.

echo [1] LATEST MODIFIED USERS (Last 5):
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT username || ' - ' || full_name || ' (Updated: ' || updated_at || ')' FROM users ORDER BY updated_at DESC LIMIT 5;"
echo.

echo [2] TODAY'S ACTIVITIES:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Users added today: ' || COUNT(*) FROM users WHERE DATE(created_at) = CURRENT_DATE;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Attendance marked today: ' || COUNT(*) FROM attendance WHERE DATE(created_at) = CURRENT_DATE;"
echo.

echo [3] RECENT LOGIN ACTIVITY:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT username || ' logged in at ' || last_login FROM users WHERE last_login IS NOT NULL ORDER BY last_login DESC LIMIT 3;"
echo.

echo ===========================================
pause