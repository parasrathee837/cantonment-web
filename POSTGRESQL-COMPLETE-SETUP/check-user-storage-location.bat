@echo off
echo ===========================================
echo Check Where "Create New User" Popup Stores Data
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Let's check ALL possible tables where users might be stored:
echo.

echo 1. USERS TABLE:
echo ===============
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, created_at FROM users ORDER BY created_at DESC;" 2>nul

echo.
echo 2. USER_COMPLETE_PROFILE TABLE:
echo ===============================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, full_name, created_at FROM user_complete_profile ORDER BY created_at DESC;" 2>nul

echo.
echo 3. USER_PROFILES TABLE:
echo =======================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, user_id, profile_data, created_at FROM user_profiles ORDER BY created_at DESC;" 2>nul

echo.
echo 4. ADMISSIONS TABLE (might store staff users):
echo ==============================================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, staff_id, staff_name, designation, created_at FROM admissions ORDER BY created_at DESC;" 2>nul

echo.
echo 5. STAFF_PERSONAL TABLE:
echo ========================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, staff_id, full_name, created_at FROM staff_personal ORDER BY created_at DESC;" 2>nul

echo.
echo ANALYSIS:
echo =========
echo.
echo Now, CREATE A NEW USER through your admin portal popup and then:
echo 1. Run this script again
echo 2. See which table(s) get new records
echo 3. That will tell us exactly where the popup stores users
echo.

echo Current total counts:
echo ---------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'users: ' || COUNT(*) FROM users;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'user_complete_profile: ' || COUNT(*) FROM user_complete_profile;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'user_profiles: ' || COUNT(*) FROM user_profiles;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'admissions: ' || COUNT(*) FROM admissions;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'staff_personal: ' || COUNT(*) FROM staff_personal;" 2>nul

echo.
echo INSTRUCTIONS:
echo ============
echo 1. Note the counts above
echo 2. Go to your admin portal
echo 3. Use "Create new user" popup to create a test user
echo 4. Run this script again
echo 5. See which counts increased - that's where the data goes!
echo.

pause