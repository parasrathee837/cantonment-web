@echo off
echo ===========================================
echo Checking Expected vs Actual Schema
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo CURRENT TABLES IN YOUR DATABASE:
echo --------------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"

echo.
echo CHECKING FOR COMMON CBA PORTAL TABLES:
echo --------------------------------------

echo Checking for 'staff' or 'employees' table...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name IN ('staff', 'employees', 'staff_details')) THEN 'FOUND' ELSE 'NOT FOUND' END;"

echo Checking for 'attendance' table...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance') THEN 'FOUND' ELSE 'NOT FOUND' END;"

echo Checking for 'payslips' table...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payslips') THEN 'FOUND' ELSE 'NOT FOUND' END;"

echo Checking for 'leaves' table...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'leaves') THEN 'FOUND' ELSE 'NOT FOUND' END;"

echo Checking for 'codes' table...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'codes') THEN 'FOUND' ELSE 'NOT FOUND' END;"

echo.
echo USERS TABLE DETAILED STRUCTURE:
echo -------------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\d users"

echo.
pause