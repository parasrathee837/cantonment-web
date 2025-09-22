@echo off
echo ===========================================
echo Test Delete Endpoint with Real User ID
echo ===========================================
echo.

echo Now that we have testuser (ID 3), let's test the delete endpoint:
echo.

echo Testing DELETE /api/users-normalized/3 (testuser):
curl -X DELETE -s -w "Status: %%{http_code}\n" http://localhost:5000/api/users-normalized/3

echo.
echo If you get 404 again, the route definitely doesn't exist.
echo If you get 401, you need authentication.
echo If you get 200, it worked!
echo.

echo Current users after test:
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role FROM users ORDER BY id;"

echo.
echo NEXT STEPS:
echo ==========
echo.
echo 1. If the DELETE worked above, then try deleting testuser from your admin portal
echo 2. If still 404, your backend routes/users-normalized.js is missing DELETE handler
echo 3. If 401, you need to login first in your admin portal, then try delete
echo.

pause