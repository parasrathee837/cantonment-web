@echo off
echo ===========================================
echo SIMPLE USER CREATION TEST
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Current users in database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, role FROM users ORDER BY id;"
echo.

echo Testing user creation endpoints WITHOUT authentication:
echo ======================================================

echo 1. Testing /api/auth/register:
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"simpletest1\",\"password\":\"test123\",\"full_name\":\"Simple Test 1\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/register
echo.

echo 2. Testing /api/users (might need auth):
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"simpletest2\",\"password\":\"test123\",\"full_name\":\"Simple Test 2\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/users
echo.

echo 3. Testing /api/admissions (for staff creation):
curl -X POST -H "Content-Type: application/json" -d "{\"staff_name\":\"Simple Staff Test\",\"designation\":\"Test Position\",\"mobile_number\":\"1234567890\",\"date_of_birth\":\"1990-01-01\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/admissions
echo.

echo Checking database after tests:
echo ==============================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, role, created_at FROM users ORDER BY created_at DESC LIMIT 5;"
echo.

echo Checking admissions table:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, staff_name, designation, mobile_number FROM admissions ORDER BY created_at DESC LIMIT 5;"
echo.

echo RESULTS INTERPRETATION:
echo =======================
echo - 200/201 + new database record = WORKING
echo - 200/201 + no database record = Backend issue
echo - 401 = Needs authentication
echo - 404 = Endpoint doesn't exist
echo - 500 = Server error
echo.

pause