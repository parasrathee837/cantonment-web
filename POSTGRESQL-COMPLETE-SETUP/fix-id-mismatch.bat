@echo off
echo ===========================================
echo Fix ID Mismatch Issue
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo PROBLEM IDENTIFIED:
echo ===================
echo.
echo testuser exists with DIFFERENT IDs in each table:
echo - users table: ID 3
echo - user_complete_profile table: ID 4
echo.
echo Frontend shows user from user_complete_profile (ID 4)
echo But tries to delete from users table (ID 4 doesn't exist there)
echo This causes 404 → HTML error → JSON parse error!
echo.

echo SOLUTION: Sync the IDs properly
echo.

echo Current state:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'users table: ID=' || id || ', username=' || username FROM users WHERE username = 'testuser';"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'user_complete_profile: ID=' || id || ', username=' || username FROM user_complete_profile WHERE username = 'testuser';"

echo.
echo Option 1: Delete testuser and recreate with matching IDs
set /p fix1="Fix by recreating testuser with matching IDs? (Y/N): "
if /i "%fix1%"=="Y" (
    echo.
    echo Deleting testuser from both tables...
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "DELETE FROM users WHERE username = 'testuser';"
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "DELETE FROM user_complete_profile WHERE username = 'testuser';"
    
    echo.
    echo Recreating testuser with same ID in both tables...
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO users (id, username, password, role, created_at, updated_at) VALUES (10, 'testuser', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);"
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO user_complete_profile (id, username, password, role, full_name, created_at, updated_at) VALUES (10, 'testuser', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'user', 'Test User', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);"
    
    echo.
    echo testuser now has ID 10 in BOTH tables!
    echo.
    echo Verification:
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'users: ID=' || id FROM users WHERE username = 'testuser';"
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'user_complete_profile: ID=' || id FROM user_complete_profile WHERE username = 'testuser';"
    
    echo.
    echo NOW TRY:
    echo 1. Refresh your admin portal
    echo 2. Try to delete testuser
    echo 3. It should work because IDs match!
)

echo.
echo Option 2: Fix the root cause - user creation process
echo.
echo The real fix is to ensure when users are created through admin portal,
echo they get the SAME ID in both tables.
echo.

echo This happens because:
echo 1. Admin portal creates user in user_complete_profile table
echo 2. Some trigger/process creates user in users table  
echo 3. But they get different auto-generated IDs
echo.

echo PERMANENT FIX NEEDED:
echo ======================
echo.
echo Your user creation process needs to:
echo 1. Get next available ID
echo 2. Use SAME ID for both tables
echo 3. Or use username as lookup instead of ID
echo.

echo For now, test with the fixed testuser (ID 10 in both tables)
echo Delete should work perfectly!
echo.
pause