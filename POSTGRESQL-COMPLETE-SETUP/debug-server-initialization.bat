@echo off
echo ===========================================
echo Debug Server Initialization Issue
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Checking why server says "Database not initialized"...
echo.

echo 1. Database Status:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Tables: ' || COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Admin users: ' || COUNT(*) FROM users WHERE role = 'admin';"

echo.
echo 2. Checking if key tables exist that server might be looking for:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN '[OK] users table exists' ELSE '[MISSING] users table' END;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_complete_profile') THEN '[OK] user_complete_profile exists' ELSE '[MISSING] user_complete_profile' END;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admissions') THEN '[OK] admissions exists' ELSE '[MISSING] admissions' END;"

echo.
echo 3. Testing the actual initialization check the server might be doing:
echo.
echo Testing if admin user exists in users table:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT username, role FROM users WHERE role = 'admin' LIMIT 1;"

echo.
echo Testing if users have proper structure:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'users' ORDER BY ordinal_position;"

echo.
echo 4. The server might be checking for specific data or columns.
echo    Even though the schema file exists, the server's code might have
echo    additional checks for database readiness.
echo.

echo SOLUTION OPTIONS:
echo.
echo Option 1: The database is actually working fine, ignore the message
echo   - Your 37 tables exist and data can be saved
echo   - The message might be cosmetic
echo   - Try using the application anyway
echo.
echo Option 2: Restart the server completely
echo   - Stop the server (Ctrl+C)
echo   - Start it again
echo   - Sometimes it takes a restart to recognize changes
echo.
echo Option 3: The server code has hardcoded checks
echo   - It might check for specific table contents
echo   - Or specific admin user setup
echo   - We would need to see the server code to know exactly
echo.

echo Test your application now - it might work despite the message!
echo.
pause