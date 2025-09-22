@echo off
REM Live monitoring specifically for admin portal actions

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo ===========================================
echo ADMIN PORTAL ACTIONS MONITOR
echo ===========================================
echo This shows exactly what happens when you:
echo - Create users through admin portal popup
echo - Try to delete users through admin portal
echo ===========================================
echo Keep this window open while using admin portal
echo ===========================================

:loop
cls
echo ===========================================
echo ADMIN PORTAL MONITOR - %date% %time%
echo ===========================================
echo.

echo 👥 CURRENT USERS IN SYSTEM:
echo ===========================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'ID: ' || id || ' | ' || username || ' | ' || role || ' | Created: ' || created_at FROM users ORDER BY id;" 2>nul

echo.
echo 📊 USER COUNTS:
echo ==============
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Users table: ' || COUNT(*) || ' records' FROM users;" 2>nul
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'User_complete_profile: ' || COUNT(*) || ' records' FROM user_complete_profile;" 2>nul

echo.
echo 🔄 RECENT ACTIVITY (Last 2 minutes):
echo ===================================
echo [USER CREATION:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ Created: ' || username || ' (ID: ' || id || ') at ' || created_at FROM users WHERE created_at > NOW() - INTERVAL '2 minutes' ORDER BY created_at DESC;" 2>nul

echo [USER UPDATES:]
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ Updated: ' || username || ' (ID: ' || id || ') at ' || updated_at FROM users WHERE updated_at > NOW() - INTERVAL '2 minutes' AND updated_at != created_at ORDER BY updated_at DESC;" 2>nul

echo [USER DELETIONS:]
REM Check for missing IDs that might indicate deletions
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '→ User deleted (if count decreased)' WHERE (SELECT COUNT(*) FROM users) < (SELECT MAX(id) FROM users);" 2>nul

echo.
echo 💡 ADMIN PORTAL TESTING INSTRUCTIONS:
echo ====================================
echo.
echo 1. CREATE TEST: Use admin portal "Create new users popup"
echo    - You should see new user appear above immediately
echo.
echo 2. DELETE TEST: Try to delete the user you just created
echo    - If successful: User disappears from list above
echo    - If error: User remains, check browser F12 Network tab
echo.
echo 3. DEBUGGING: If delete fails:
echo    - Press F12 in browser
echo    - Go to Network tab  
echo    - Try delete again
echo    - Look for DELETE request and its response
echo.

echo Next refresh in 10 seconds...
echo (Create/delete users in admin portal to see live changes)
timeout /t 10 >nul
goto loop