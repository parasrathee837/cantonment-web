@echo off
echo ===========================================
echo TEST WORKING ENDPOINTS WITH CORRECT FORMAT
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Current users in database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, role FROM users;"
echo.

echo Step 1: Test /api/auth/register with correct validation
echo =======================================================
echo Testing with 8+ char password, email, and valid role...

curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"validtest1\",\"password\":\"password123\",\"email\":\"test1@cba.com\",\"role\":\"user\",\"full_name\":\"Valid Test User\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/register
echo.
echo.

echo Step 2: Get admin authentication token
echo =======================================
echo Logging in as admin...

curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin\"}" -s http://localhost:5000/api/auth/login > temp_login.json

echo Admin login response:
type temp_login.json
echo.

echo Step 3: Test authenticated admin endpoints
echo ==========================================
echo.

echo Manual token test - you'll need to copy the token from above response
echo and manually test this command:
echo.
echo curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer YOUR_TOKEN_HERE" -d "{\"username\":\"admintest2\",\"full_name\":\"Admin Created User\",\"email\":\"admin@test.com\",\"password\":\"password123\",\"role\":\"user\"}" http://localhost:5000/api/admin/users
echo.

echo Step 4: Check what endpoints actually exist
echo ============================================

echo Testing common endpoint paths:
echo /api/auth/register: 
curl -s -w " [%%{http_code}]" http://localhost:5000/api/auth/register
echo.

echo /api/auth/login:
curl -s -w " [%%{http_code}]" http://localhost:5000/api/auth/login  
echo.

echo /api/admin:
curl -s -w " [%%{http_code}]" http://localhost:5000/api/admin
echo.

echo /api/users:
curl -s -w " [%%{http_code}]" http://localhost:5000/api/users
echo.

echo /api/users-enhanced:
curl -s -w " [%%{http_code}]" http://localhost:5000/api/users-enhanced
echo.

echo /api/admissions:
curl -s -w " [%%{http_code}]" http://localhost:5000/api/admissions
echo.

echo Step 5: Check database after tests
echo ===================================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, email, role, created_at FROM users ORDER BY created_at DESC;"
echo.

echo ENDPOINT SUMMARY:
echo ================
echo.
echo Based on your error responses:
echo - /api/auth/register EXISTS (gave validation error, not 404)
echo - /api/users does NOT EXIST (404 error)  
echo - /api/admissions EXISTS but needs authentication
echo.
echo Your frontend is probably calling /api/users which doesn't exist!
echo The working endpoints appear to be:
echo - /api/auth/register (for registration)
echo - /api/admin/users (for admin user creation)
echo - /api/admissions (for staff/admission records)
echo.

del temp_login.json 2>nul
pause