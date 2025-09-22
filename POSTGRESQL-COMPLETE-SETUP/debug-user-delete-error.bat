@echo off
echo ===========================================
echo Debug User Delete Error
echo ===========================================
echo.

echo Your frontend is trying to DELETE /api/users-normalized/1
echo but getting 404 Not Found (HTML response instead of JSON)
echo.

echo Let's check what user endpoints actually exist...
echo.

echo Testing available user endpoints:
echo.

echo 1. Testing /api/users-normalized:
curl -s -w "Status: %%{http_code}\n" http://localhost:5000/api/users-normalized

echo.
echo 2. Testing /api/users:
curl -s -w "Status: %%{http_code}\n" http://localhost:5000/api/users

echo.
echo 3. Testing /api/users-enhanced:
curl -s -w "Status: %%{http_code}\n" http://localhost:5000/api/users-enhanced

echo.
echo 4. Let's check what users exist in database:

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role FROM users ORDER BY id;"

echo.
echo 5. Check user_complete_profile table:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role FROM user_complete_profile ORDER BY id;"

echo.
echo ISSUE ANALYSIS:
echo ==============
echo.
echo The frontend expects /api/users-normalized/1 endpoint to exist
echo for DELETE operations, but your server returns 404.
echo.
echo This means either:
echo 1. The route is not registered in your backend
echo 2. The route file is missing
echo 3. The route has different authentication requirements
echo 4. The route expects different URL format
echo.

echo IMMEDIATE FIX:
echo =============
echo.
echo Option 1: Check your backend console for route registration errors
echo Option 2: The user might not exist with ID=1
echo Option 3: Try deleting a different user ID
echo.

echo Let's verify if user ID 1 exists:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'User ID 1: ' || CASE WHEN EXISTS(SELECT 1 FROM users WHERE id = 1) THEN 'EXISTS' ELSE 'NOT FOUND' END;"

echo.
echo Current users that can be deleted:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'DELETE /api/users-normalized/' || id as endpoint_to_try, username, role FROM users WHERE role != 'admin';"

echo.
pause