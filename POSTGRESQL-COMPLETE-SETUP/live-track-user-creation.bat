@echo off
REM Live tracking to see exactly where new users are stored

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo ===========================================
echo LIVE TRACK: "Create New User" Popup Storage
echo ===========================================
echo This will show EXACTLY where your admin portal
echo stores users when you use the "Create new user" popup
echo ===========================================
echo Keep this running and create a user in admin portal
echo ===========================================

:loop
cls
echo ===========================================
echo LIVE USER CREATION TRACKER - %date% %time%
echo ===========================================
echo.

echo 📊 TABLE RECORD COUNTS:
echo =======================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'users: ' || COUNT(*) || ' records' FROM users;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'user_complete_profile: ' || COUNT(*) || ' records' FROM user_complete_profile;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'user_profiles: ' || COUNT(*) || ' records' FROM user_profiles;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'admissions: ' || COUNT(*) || ' records' FROM admissions;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'staff_personal: ' || COUNT(*) || ' records' FROM staff_personal;" 2>nul

echo.
echo 🔄 RECENT ADDITIONS (Last 30 seconds):
echo ======================================
echo [USERS TABLE]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ NEW: ' || username || ' (ID: ' || id || ') at ' || created_at FROM users WHERE created_at > NOW() - INTERVAL '30 seconds' ORDER BY created_at DESC;" 2>nul

echo [USER_COMPLETE_PROFILE TABLE]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ NEW: ' || username || ' (ID: ' || id || ') at ' || created_at FROM user_complete_profile WHERE created_at > NOW() - INTERVAL '30 seconds' ORDER BY created_at DESC;" 2>nul

echo [USER_PROFILES TABLE]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ NEW: Profile for user_id ' || user_id || ' (ID: ' || id || ') at ' || created_at FROM user_profiles WHERE created_at > NOW() - INTERVAL '30 seconds' ORDER BY created_at DESC;" 2>nul

echo [ADMISSIONS TABLE]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ NEW: ' || COALESCE(staff_name, 'No name') || ' (ID: ' || id || ') at ' || created_at FROM admissions WHERE created_at > NOW() - INTERVAL '30 seconds' ORDER BY created_at DESC;" 2>nul

echo [STAFF_PERSONAL TABLE]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ NEW: ' || COALESCE(full_name, 'No name') || ' (ID: ' || id || ') at ' || created_at FROM staff_personal WHERE created_at > NOW() - INTERVAL '30 seconds' ORDER BY created_at DESC;" 2>nul

echo.
echo 💡 INSTRUCTIONS:
echo ================
echo 1. Keep this window open
echo 2. Go to your admin portal 
echo 3. Use "Create new user" popup
echo 4. Watch which table shows "→ NEW:" entry
echo 5. That's where your users are stored!
echo.

echo Next update in 5 seconds...
echo (Create a user now to see where it goes!)
timeout /t 5 >nul
goto loop