@echo off
REM Simple database check - Works with basic schema

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo ===========================================
echo QUICK DATABASE CHECK (Simple Schema)
echo ===========================================
echo.

echo [1] TOTAL USERS IN SYSTEM:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total users: ' || COUNT(*) FROM users;"
echo.

echo [2] RECENT USERS (Last 5):
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, email, role, created_at FROM users ORDER BY created_at DESC LIMIT 5;"
echo.

echo [3] USERS BY ROLE:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT role, COUNT(*) as count FROM users GROUP BY role;"
echo.

echo [4] DATABASE TABLES:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
echo.

echo ===========================================
echo To see your database structure, run:
echo check-database-schema.bat
echo ===========================================
pause