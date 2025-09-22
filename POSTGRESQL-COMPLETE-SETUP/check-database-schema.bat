@echo off
echo ===========================================
echo Database Schema Checker
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Checking database structure...
echo.

echo [1] TABLES IN DATABASE:
echo -----------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"
echo.

echo [2] COLUMNS IN USERS TABLE:
echo ---------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'users' ORDER BY ordinal_position;"
echo.

echo [3] SAMPLE USER DATA:
echo ---------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT * FROM users LIMIT 2;"
echo.

echo [4] ALL TABLE STRUCTURES:
echo -------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\dt+"
echo.

pause