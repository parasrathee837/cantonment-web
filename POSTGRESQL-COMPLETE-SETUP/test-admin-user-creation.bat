@echo off
echo ===========================================
echo TEST ADMIN USER CREATION WITH AUTHENTICATION
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Step 1: Check current users in database
echo ======================================
echo Current users in database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, role FROM users ORDER BY created_at DESC;"
echo.

echo Step 2: Get admin login token
echo ==============================
echo Logging in as admin to get authentication token...

curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin\"}" -s http://localhost:5000/api/auth/login > login_response.txt

echo Login response:
type login_response.txt
echo.

echo Extracting token from response...
for /f "tokens=*" %%i in ('type login_response.txt ^| findstr /r "\"token\"" ^| for /f "tokens=2 delims=:" %%j in ("%%i") do echo %%j ^| for /f "tokens=1 delims=," %%k in ("%%j") do echo %%k ^| for /f "tokens=1 delims="""" %%l in ("%%k") do echo %%l') do set TOKEN=%%i

if "%TOKEN%"=="" (
    echo ERROR: Could not extract token from login response
    echo Please check if admin credentials are correct
    pause
    exit /b 1
) else (
    echo Token extracted successfully: %TOKEN%
)

echo.

echo Step 3: Test admin user creation endpoint
echo =========================================
echo Creating test user via /api/admin/users with authentication...

curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer %TOKEN%" -d "{\"username\":\"admintest1\",\"full_name\":\"Admin Test User\",\"email\":\"test@cba.com\",\"password\":\"test123\",\"role\":\"user\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/admin/users
echo.
echo.

echo Step 4: Check if user was created in database
echo =============================================
echo Users after admin creation attempt:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, role, created_at FROM users WHERE username LIKE 'admintest%%' ORDER BY created_at DESC;"
echo.

echo Step 5: Test the exact frontend endpoint
echo ========================================
echo Your frontend might be calling different endpoints. Let's test them:
echo.

echo Testing /api/users with auth:
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer %TOKEN%" -d "{\"username\":\"frontendtest1\",\"full_name\":\"Frontend Test\",\"password\":\"test123\",\"role\":\"user\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/users
echo.

echo Testing /api/auth/register:
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"registertest1\",\"password\":\"test123\",\"full_name\":\"Register Test\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/register
echo.

echo Step 6: Final database check
echo ============================
echo All users in database after all tests:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, role, created_at FROM users ORDER BY created_at DESC LIMIT 10;"
echo.

echo Step 7: Test user deletion
echo ==========================
echo Getting user ID for deletion test...
for /f "skip=2 tokens=1" %%i in ('psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT id FROM users WHERE username LIKE 'admintest%%' LIMIT 1;"') do set TEST_USER_ID=%%i

if not "%TEST_USER_ID%"=="" (
    echo Testing delete user ID %TEST_USER_ID% via /api/admin/users/%TEST_USER_ID%:
    curl -X DELETE -H "Authorization: Bearer %TOKEN%" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/admin/users/%TEST_USER_ID%
    echo.
    
    echo Users after deletion:
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username FROM users WHERE username LIKE 'admintest%%';"
) else (
    echo No test user found to delete
)

echo.
echo SUMMARY:
echo ========
echo 1. Check if users were created successfully
echo 2. Check HTTP status codes (200/201 = success, 401 = auth issue, 404 = endpoint missing)
echo 3. If 401 errors, token extraction failed
echo 4. If 404 errors, frontend is calling wrong endpoints
echo 5. If 200/201 but no database records, there's a backend storage issue
echo.

del login_response.txt 2>nul
pause