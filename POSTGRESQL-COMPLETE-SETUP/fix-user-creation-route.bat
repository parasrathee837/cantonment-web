@echo off
echo ===========================================
echo Fix User Creation Route Issue
echo ===========================================
echo.

echo PROBLEM IDENTIFIED:
echo ===================
echo.
echo Your admin portal popup is trying to POST to routes that don't exist:
echo ❌ /api/users (404 - route missing)
echo ❌ /api/users-enhanced (404 - route missing)
echo ✅ /api/users-normalized (401 - route exists, needs auth)
echo.

echo SOLUTION: Your popup should use /api/users-normalized
echo.

echo Let's test if /api/users-normalized works with proper authentication:
echo.

echo Step 1: First, make sure you're logged into admin portal
echo Step 2: We'll test the working route
echo.

set /p logged_in="Are you currently logged into the admin portal? (Y/N): "

if /i "%logged_in%"=="N" (
    echo.
    echo Please login first:
    echo 1. Go to http://localhost:5000
    echo 2. Login with your admin credentials
    echo 3. Then come back here
    pause
    exit /b 0
)

echo.
echo FRONTEND FIX NEEDED:
echo ===================
echo.
echo Your admin portal's "Create new user" popup needs to be updated to:
echo 1. Use the correct endpoint: /api/users-normalized
echo 2. Include authentication headers from your admin session
echo.

echo IMMEDIATE WORKAROUND:
echo =====================
echo.
echo Let's manually create a test user in the database so you can test deletion:
echo.

set /p create_manual="Manually create a test user for deletion testing? (Y/N): "
if /i "%create_manual%"=="Y" (
    echo.
    echo Creating test user manually...
    
    set PGHOST=localhost
    set PGPORT=5432
    set PGDATABASE=cba_portal
    set PGUSER=postgres
    set PGPASSWORD=CBA@2025Portal
    
    REM Create user with ID 15 in both tables
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO users (id, username, password, role, created_at, updated_at) VALUES (15, 'manualtest', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);"
    
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO user_complete_profile (id, username, password, role, full_name, created_at, updated_at) VALUES (15, 'manualtest', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'user', 'Manual Test User', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);"
    
    echo.
    echo ✅ Test user 'manualtest' created with ID 15 in both tables
    echo.
    echo NOW TEST:
    echo 1. Refresh your admin portal (F5)
    echo 2. You should see 'manualtest' in the user list
    echo 3. Try to delete 'manualtest'
    echo 4. It should work because IDs match in both tables
)

echo.
echo LONG-TERM FIX:
echo ==============
echo.
echo Your frontend code needs to be updated to:
echo 1. Use POST /api/users-normalized for user creation
echo 2. Include proper authentication headers
echo 3. Handle the response correctly
echo.
echo This is a frontend code issue, not a database issue.
echo.

echo VERIFICATION:
echo ============
echo.
echo Current users in database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role FROM users ORDER BY id;" 2>nul
echo.
echo These users should appear in your admin portal user list.
echo If manualtest appears, try deleting it to test if deletion works.
echo.

pause