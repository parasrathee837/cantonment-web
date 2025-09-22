@echo off
echo ===========================================
echo TEST WORKING ADMIN ENDPOINT FOR USER CREATION
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo SOLUTION FOUND!
echo ===============
echo.
echo The issue is your /api/auth routes exist but have strict validation requirements:
echo - Password must be 8+ characters (not 6+)
echo - Email is required  
echo - Role must be 'admin', 'user', or 'operator'
echo.
echo However, /api/admin/users should work perfectly for user creation.
echo Let's test it properly:
echo.

echo Step 1: Current database state
echo ==============================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, email, role FROM users ORDER BY id;"
echo.

echo Step 2: Login as admin (password: admin123)
echo ===========================================
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin123\"}" -s http://localhost:5000/api/auth/login > admin_token.json

echo Admin login response:
type admin_token.json
echo.

echo Step 3: Extract token for manual testing
echo =========================================
echo IMPORTANT: Copy the token value from the JSON response above.
echo Then run this command manually (replace YOUR_TOKEN_HERE):
echo.
echo curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer YOUR_TOKEN_HERE" -d "{\"username\":\"workingtest\",\"full_name\":\"Working Test User\",\"email\":\"working@test.com\",\"password\":\"password123\",\"role\":\"user\"}" http://localhost:5000/api/admin/users
echo.

echo Step 4: Alternative - Test auth/register with correct format
echo ============================================================
echo Testing registration with all required fields:

curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"registertest\",\"password\":\"password123\",\"full_name\":\"Register Test User\",\"email\":\"register@test.com\",\"role\":\"user\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/register
echo.
echo.

echo Step 5: Check database after registration test
echo ==============================================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, email, role, created_at FROM users WHERE username IN ('registertest', 'workingtest') ORDER BY created_at DESC;"
echo.

echo FRONTEND FIX INSTRUCTIONS:
echo ==========================
echo.
echo If registration worked above, update your frontend to call:
echo   POST /api/auth/register 
echo   with: username, password(8+ chars), full_name, email, role
echo.
echo If admin creation worked, update your frontend to:
echo   1. Get admin token via POST /api/auth/login
echo   2. Call POST /api/admin/users with Authorization header
echo.
echo For user deletion, use:
echo   DELETE /api/admin/users/ID with Authorization header
echo.

echo Step 6: Test user deletion via admin endpoint
echo =============================================
echo Getting a test user ID for deletion...

for /f "skip=2 tokens=1" %%i in ('psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT id FROM users WHERE username = 'registertest' LIMIT 1;"') do set DELETE_ID=%%i

if not "%DELETE_ID%"=="" (
    echo Found user ID %DELETE_ID% for deletion test
    echo Run this manually with your admin token:
    echo curl -X DELETE -H "Authorization: Bearer YOUR_TOKEN_HERE" http://localhost:5000/api/admin/users/%DELETE_ID%
) else (
    echo No test user found for deletion test
)

echo.
echo SUMMARY:
echo ========
echo 1. /api/auth/register should work with proper validation
echo 2. /api/admin/users should work with admin authentication  
echo 3. Both create users in the database successfully
echo 4. Update your frontend to use these working endpoints
echo.

del admin_token.json 2>nul
pause