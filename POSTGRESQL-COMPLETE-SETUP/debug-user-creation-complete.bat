@echo off
echo ===========================================
echo COMPLETE USER CREATION DEBUGGING
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Current directory: %cd%
echo.

echo Step 1: Check current database state
echo ===================================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT COUNT(*) as users_count FROM users;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT COUNT(*) as profiles_count FROM user_complete_profile;"

echo.
echo Step 2: Test ALL possible user creation endpoints
echo ===============================================

echo Testing /api/users (POST):
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"apitest1\",\"password\":\"test123\",\"role\":\"user\"}" -s -w " [HTTP %%{http_code}]\n" http://localhost:5000/api/users

echo.
echo Testing /api/auth/register (POST):
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"apitest2\",\"password\":\"test123\"}" -s -w " [HTTP %%{http_code}]\n" http://localhost:5000/api/auth/register

echo.
echo Testing /api/admin/users (POST):
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"apitest3\",\"password\":\"test123\",\"role\":\"user\"}" -s -w " [HTTP %%{http_code}]\n" http://localhost:5000/api/admin/users

echo.
echo Testing /api/users-enhanced (POST):
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"apitest4\",\"password\":\"test123\",\"role\":\"user\"}" -s -w " [HTTP %%{http_code}]\n" http://localhost:5000/api/users-enhanced

echo.
echo Testing /api/admissions (POST):
curl -X POST -H "Content-Type: application/json" -d "{\"staff_name\":\"API Test\",\"designation\":\"Test\",\"mobile_number\":\"1234567890\"}" -s -w " [HTTP %%{http_code}]\n" http://localhost:5000/api/admissions

echo.
echo Step 3: Check if any data was created by API tests
echo =================================================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, created_at FROM users WHERE username LIKE 'apitest%%' ORDER BY created_at DESC;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, staff_name, created_at FROM admissions WHERE staff_name LIKE '%%API Test%%' ORDER BY created_at DESC;"

echo.
echo Step 4: Navigate to project root and check route files
echo =====================================================

if exist "..\backend\routes" (
    echo Found backend directory one level up!
    echo.
    echo Route files in backend/routes/:
    dir "..\backend\routes\*.js" /b
    echo.
    echo Checking for user-related routes:
    if exist "..\backend\routes\users.js" echo [✓] users.js exists
    if exist "..\backend\routes\users-enhanced.js" echo [✓] users-enhanced.js exists
    if exist "..\backend\routes\users-normalized.js" echo [✓] users-normalized.js exists
    if exist "..\backend\routes\auth.js" echo [✓] auth.js exists
    if exist "..\backend\routes\admin.js" echo [✓] admin.js exists
    if not exist "..\backend\routes\users-normalized.js" echo [✗] users-normalized.js MISSING
    
    echo.
    echo Checking server.js for route registration:
    if exist "..\backend\server.js" (
        echo.
        echo Routes registered in server.js:
        findstr /i "app.use.*api" "..\backend\server.js"
    ) else if exist "..\server.js" (
        echo.
        echo Routes registered in server.js:
        findstr /i "app.use.*api" "..\server.js"
    ) else (
        echo server.js not found
    )
    
) else (
    echo Backend directory not found at expected location
    echo Current files:
    dir
)

echo.
echo Step 5: Identify the actual working endpoint
echo ==========================================
echo.
echo From the API tests above, look for:
echo - 200/201 responses (working endpoints)
echo - 401 responses (working but needs auth)
echo - 404 responses (endpoints don't exist)
echo.

echo DIAGNOSIS SUMMARY:
echo ==================
echo.
echo 1. Current user count in database
echo 2. Which API endpoints actually work
echo 3. Which route files exist in your backend
echo 4. What your server.js actually registers
echo.
echo This will tell us exactly why user creation fails!
echo.

pause