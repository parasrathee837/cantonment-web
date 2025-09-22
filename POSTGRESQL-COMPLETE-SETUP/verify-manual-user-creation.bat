@echo off
echo ===========================================
echo Verify Manual User Creation
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Checking if manualtest user was actually created...
echo.

echo Current users in both tables:
echo.
echo USERS TABLE:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, created_at FROM users ORDER BY id;"

echo.
echo USER_COMPLETE_PROFILE TABLE:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, full_name, created_at FROM user_complete_profile ORDER BY id;"

echo.
echo Let's create the manualtest user properly:
echo.

set /p create_again="Create manualtest user for deletion testing? (Y/N): "
if /i "%create_again%"=="Y" (
    echo.
    echo Creating manualtest user with ID 15...
    
    REM Insert into users table
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO users (id, username, password, role, created_at, updated_at) VALUES (15, 'manualtest', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) ON CONFLICT (id) DO NOTHING;"
    
    REM Insert into user_complete_profile table
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO user_complete_profile (id, username, password, role, full_name, created_at, updated_at) VALUES (15, 'manualtest', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'user', 'Manual Test User', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) ON CONFLICT (id) DO NOTHING;"
    
    echo.
    echo Verification - users after creation:
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role FROM users WHERE username = 'manualtest';"
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role FROM user_complete_profile WHERE username = 'manualtest';"
    
    echo.
    echo ✅ manualtest user should now exist with ID 15 in both tables
)

echo.
echo TESTING INSTRUCTIONS:
echo =====================
echo.
echo 1. Refresh your admin portal (press F5)
echo 2. Look for 'manualtest' user in the user list
echo 3. Try to delete 'manualtest' user
echo 4. Open browser Developer Tools (F12) → Network tab
echo 5. See what DELETE request is sent and if it succeeds
echo.

echo Expected DELETE request: DELETE /api/users-normalized/15
echo Should return: 200 OK (success) instead of 404
echo.

echo If deletion works: ✅ Problem solved!
echo If deletion fails: Check Network tab for the exact error
echo.

echo Current total users:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT COUNT(*) || ' users in database' FROM users;"

pause