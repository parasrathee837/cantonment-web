@echo off
echo ===========================================
echo Prevent Future ID Mismatch Issues
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo To prevent this issue from happening again when you create users:
echo.

echo SOLUTION 1: Sync the ID sequences
echo ================================
echo.
echo Make sure both tables use the same ID counter:

echo Current max IDs:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'users table max ID: ' || COALESCE(MAX(id), 0) FROM users;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'user_complete_profile max ID: ' || COALESCE(MAX(id), 0) FROM user_complete_profile;"

echo.
echo Current sequence values:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'users_id_seq: ' || last_value FROM users_id_seq;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'user_complete_profile_id_seq: ' || last_value FROM user_complete_profile_id_seq;" 2>nul

echo.
set /p sync="Sync the sequences to prevent future mismatches? (Y/N): "
if /i "%sync%"=="Y" (
    echo.
    echo Syncing sequences to start from 20 for both tables...
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT setval('users_id_seq', 20);" 2>nul
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT setval('user_complete_profile_id_seq', 20);" 2>nul
    
    echo.
    echo ✅ Sequences synchronized!
    echo Next user created will get ID 21 in both tables.
)

echo.
echo SOLUTION 2: Create a synchronized user creation function
echo =======================================================
echo.

set /p create_func="Create a function to ensure synchronized user creation? (Y/N): "
if /i "%create_func%"=="Y" (
    echo.
    echo Creating synchronized user creation function...
    
    REM Create a function that inserts into both tables with same ID
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "
    CREATE OR REPLACE FUNCTION create_user_synchronized(
        p_username VARCHAR(100),
        p_password VARCHAR(255),
        p_role VARCHAR(20) DEFAULT 'user',
        p_full_name VARCHAR(100) DEFAULT NULL
    ) RETURNS INTEGER AS \$\$
    DECLARE
        new_id INTEGER;
    BEGIN
        -- Get next ID from users sequence
        SELECT nextval('users_id_seq') INTO new_id;
        
        -- Insert into users table
        INSERT INTO users (id, username, password, role, created_at, updated_at)
        VALUES (new_id, p_username, p_password, p_role, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        
        -- Insert into user_complete_profile with SAME ID
        INSERT INTO user_complete_profile (id, username, password, role, full_name, created_at, updated_at)
        VALUES (new_id, p_username, p_password, p_role, COALESCE(p_full_name, p_username), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        
        RETURN new_id;
    END;
    \$\$ LANGUAGE plpgsql;"
    
    echo.
    echo ✅ Function created!
    echo.
    echo Test the function:
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT create_user_synchronized('synctest', 'password123', 'user', 'Sync Test User') as new_user_id;"
    
    echo.
    echo Verify both tables have same ID:
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'users: ID=' || id FROM users WHERE username = 'synctest';"
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'user_complete_profile: ID=' || id FROM user_complete_profile WHERE username = 'synctest';"
    
    echo.
    echo Your backend should use this function instead of direct INSERT statements!
)

echo.
echo SOLUTION 3: Quick test of current fix
echo ===================================
echo.
echo Your testuser (ID 10) should now be deletable.
echo Try deleting it from admin portal to confirm the fix works!
echo.

echo Current users with matching IDs:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "
SELECT 
    u.id as users_id, 
    ucp.id as profile_id,
    u.username,
    CASE WHEN u.id = ucp.id THEN '✅ MATCH' ELSE '❌ MISMATCH' END as id_status
FROM users u 
FULL OUTER JOIN user_complete_profile ucp ON u.username = ucp.username 
ORDER BY u.id, ucp.id;"

echo.
pause