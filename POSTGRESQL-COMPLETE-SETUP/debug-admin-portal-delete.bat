@echo off
echo ===========================================
echo Debug Admin Portal User Delete Issue
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo You're logged into admin portal and created a user via "Create new users popup"
echo but getting JSON parse error when trying to delete that user.
echo.

echo Let's check what happened when you created the user...
echo.

echo Current users in database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, created_at FROM users ORDER BY created_at DESC;"

echo.
echo Current users in user_complete_profile:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, full_name, created_at FROM user_complete_profile ORDER BY created_at DESC;" 2>nul

echo.
echo ISSUE ANALYSIS:
echo ==============
echo.
echo When you create a user through admin portal popup:
echo 1. User gets added to database with a new ID
echo 2. Frontend shows the user in the list
echo 3. When you click delete, frontend sends DELETE request
echo 4. But something goes wrong and you get JSON parse error
echo.

echo Let's check what the frontend is actually trying to delete:
echo.

echo Most recent user IDs that might be getting deleted:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'Frontend probably trying: DELETE /api/users-normalized/' || id as delete_endpoint, username, role FROM users WHERE role != 'admin' ORDER BY id DESC;"

echo.
echo DEBUGGING STEPS:
echo ===============
echo.

echo Step 1: Check your browser's Developer Tools
echo   - Press F12 in your browser
echo   - Go to Network tab
echo   - Try to delete a user
echo   - See exactly what URL is being called
echo.

echo Step 2: Check what happens when you delete
echo   - Look for the actual DELETE request in Network tab
echo   - Check if it's 404, 401, or 500 error
echo   - See the response body (HTML vs JSON)
echo.

echo LIKELY ISSUES:
echo =============
echo.

echo Issue 1: Frontend using wrong table
echo   - Frontend might expect users in 'users' table
echo   - But looking in 'user_complete_profile' table
echo   - Or vice versa
echo.

echo Issue 2: ID mismatch
echo   - User created in one table with ID X
echo   - Frontend trying to delete from other table with same ID
echo   - But ID doesn't exist in target table
echo.

echo Issue 3: Route expects different authentication
echo   - Admin portal login token might not work for delete route
echo   - Route might expect different auth headers
echo.

echo QUICK TEST:
echo ==========
echo.

echo Let's create a fresh test user and try to delete it:
set /p test="Create a test user to debug delete process? (Y/N): "
if /i "%test%"=="Y" (
    echo.
    echo Creating test user in both tables...
    
    REM Get next ID for users table
    for /f %%i in ('psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT COALESCE(MAX(id), 0) + 1 FROM users;"') do set NEXT_ID=%%i
    
    echo Next user ID will be: %NEXT_ID%
    
    REM Add to users table
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO users (username, password, role, created_at, updated_at) VALUES ('debuguser', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);"
    
    REM Add to user_complete_profile table with same ID
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO user_complete_profile (id, username, password, role, full_name, created_at, updated_at) VALUES (%NEXT_ID%, 'debuguser', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'user', 'Debug User', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);" 2>nul
    
    echo.
    echo Test user 'debuguser' created with ID %NEXT_ID%
    echo.
    echo NOW TRY THIS:
    echo 1. Refresh your admin portal
    echo 2. You should see 'debuguser' in the user list
    echo 3. Try to delete 'debuguser'
    echo 4. Check browser Network tab (F12) to see exact error
    echo.
    echo The delete request should be: DELETE /api/users-normalized/%NEXT_ID%
)

echo.
echo SOLUTION APPROACH:
echo =================
echo.
echo 1. Open browser Developer Tools (F12)
echo 2. Try to delete a user from admin portal
echo 3. Check Network tab for the exact DELETE request
echo 4. See what error code and response you get
echo 5. Report back what you see!
echo.

echo Common fixes:
echo - If 404: Route missing or wrong URL format
echo - If 401: Authentication problem
echo - If 500: Database error (user exists in one table but not another)
echo.

pause