@echo off
echo ===========================================
echo Fix User Delete Issue
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo The delete error happens because:
echo 1. Frontend calls /api/users-normalized/1 
echo 2. Server returns 404 (route not found)
echo 3. HTML error page returned instead of JSON
echo 4. Frontend tries to parse HTML as JSON → Error!
echo.

echo Let's diagnose and fix this issue...
echo.

echo Current users in database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, created_at FROM users ORDER BY id;"

echo.
echo Current users in user_complete_profile:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, created_at FROM user_complete_profile ORDER BY id;" 2>nul

echo.
echo SOLUTIONS:
echo ==========
echo.

echo Solution 1: Add a test user that can be deleted safely
set /p add_user="Add a test user for deletion testing? (Y/N): "
if /i "%add_user%"=="Y" (
    echo.
    echo Adding test user...
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO users (username, password, role, created_at, updated_at) VALUES ('testuser', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);"
    
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO user_complete_profile (username, password, role, full_name, created_at, updated_at) VALUES ('testuser', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'user', 'Test User', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);" 2>nul
    
    echo.
    echo Test user added! Now try deleting it from admin portal.
)

echo.
echo Solution 2: Check backend routes
echo Your backend might be missing the users-normalized delete route.
echo Check your backend console for any route registration errors.
echo.

echo Solution 3: Route authentication issue
echo The route might require specific authentication headers.
echo Make sure you're logged in as admin when trying to delete.
echo.

echo Solution 4: Wrong user ID
echo The frontend might be trying to delete user ID 1, but:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT CASE WHEN EXISTS(SELECT 1 FROM users WHERE id = 1) THEN 'User ID 1 exists' ELSE 'User ID 1 does NOT exist' END;"

echo.
echo Available user IDs that can be deleted:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'Try deleting user ID: ' || id || ' (' || username || ')' FROM users WHERE role != 'admin' ORDER BY id;"

echo.
echo BACKEND ROUTE CHECK:
echo ===================
echo.
echo Your backend should have this file: backend/routes/users-normalized.js
echo And it should handle DELETE requests.
echo.
echo If the route doesn't exist, that's why you get 404.
echo Check your backend console for route loading errors.
echo.

echo WORKAROUND:
echo ==========
echo.
echo If the route is broken, you can delete users manually:
set /p manual_delete="Manually delete a user from database? (Y/N): "
if /i "%manual_delete%"=="Y" (
    echo.
    echo Available users to delete:
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role FROM users WHERE role != 'admin';"
    echo.
    set /p user_id="Enter user ID to delete: "
    if not "!user_id!"=="" (
        psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "DELETE FROM user_complete_profile WHERE id = !user_id!;" 2>nul
        psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "DELETE FROM users WHERE id = !user_id! AND role != 'admin';"
        echo User deleted from database.
    )
)

echo.
echo The main issue is your backend route /api/users-normalized/[id] DELETE
echo is not working. Check backend console for specific errors.
echo.
pause