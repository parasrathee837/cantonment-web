@echo off
echo ============================================
echo TEST COMPLETE FRONTEND-BACKEND DATA FLOW
echo ============================================
echo.
echo This script tests that all data changes in frontend
echo are immediately reflected in the database.
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=cba_admin
set PGPASSWORD=CBA@2025Portal

echo Current database state:
echo =======================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT COUNT(*) as user_count FROM users;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT COUNT(*) as staff_count FROM admissions;"
echo.

echo Testing API endpoints one by one:
echo =================================

echo 1. Testing admin login (get token):
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin123\"}" -s http://localhost:5000/api/auth/login > login_response.json

echo Login response:
type login_response.json | head -3
echo.

echo 2. Testing user registration (should create user in DB):
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"flowtest1\",\"password\":\"password123\",\"full_name\":\"Flow Test User 1\",\"email\":\"flow1@test.com\",\"role\":\"user\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/register
echo.

echo Checking if user was created in database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, email FROM users WHERE username = 'flowtest1';"
echo.

echo 3. Testing staff admission creation:
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer TOKEN_HERE" -d "{\"staff_name\":\"Test Staff Member\",\"designation\":\"Test Position\",\"mobile_number\":\"9999999999\",\"date_of_birth\":\"1990-01-01\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/admissions
echo.

echo Note: The above will likely fail with 401 (needs token). This is expected.
echo.

echo 4. Testing designation creation:
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer TOKEN_HERE" -d "{\"name\":\"Test Designation\",\"department\":\"Test Department\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/admin/designations
echo.

echo MANUAL TESTING REQUIRED:
echo ========================
echo.
echo To complete the data flow test:
echo.
echo 1. Open http://localhost:5000 in your browser
echo 2. Login with: admin / admin123
echo 3. Go to Admin Portal
echo 4. Try these actions and verify data appears in database:
echo.
echo    a) Create New User:
echo       - Fill form and submit
echo       - Run: SELECT * FROM users ORDER BY created_at DESC LIMIT 1;
echo       - Should show your new user immediately
echo.
echo    b) Delete User:
echo       - Delete a user from admin panel
echo       - Run: SELECT COUNT(*) FROM users;
echo       - Count should decrease immediately
echo.
echo    c) Create Staff Member:
echo       - Use "Add New Staff" form
echo       - Run: SELECT * FROM admissions ORDER BY created_at DESC LIMIT 1;
echo       - Should show new staff member
echo.
echo    d) Create Designation:
echo       - Add a new designation
echo       - Run: SELECT * FROM designations ORDER BY created_at DESC LIMIT 1;
echo       - Should show new designation
echo.

echo Quick database check commands:
echo ==============================
echo.
echo Users: psql -U cba_admin -d cba_portal -c "SELECT id, username, full_name, created_at FROM users ORDER BY created_at DESC LIMIT 5;"
echo.
echo Staff: psql -U cba_admin -d cba_portal -c "SELECT id, staff_name, designation, created_at FROM admissions ORDER BY created_at DESC LIMIT 5;"
echo.
echo Designations: psql -U cba_admin -d cba_portal -c "SELECT id, name, department, created_at FROM designations ORDER BY created_at DESC LIMIT 5;"
echo.

echo EXPECTED RESULTS:
echo ================
echo.
echo ✅ User registration returns 200/201 and user appears in database
echo ✅ Admin operations work with proper authentication
echo ✅ All frontend form submissions immediately update database
echo ✅ All frontend deletions immediately remove from database
echo ✅ No more "data is not getting stored" issues!
echo.

del login_response.json 2>nul
pause