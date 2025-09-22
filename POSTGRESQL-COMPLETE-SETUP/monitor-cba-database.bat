@echo off
echo ===========================================
echo CBA Portal - Database Monitor
echo Configured for your database schema
echo ===========================================
echo.

REM Set PostgreSQL connection parameters
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

:menu
cls
echo ===========================================
echo CBA PORTAL DATABASE MONITOR
echo ===========================================
echo Your Tables: users, designations, nationalities, 
echo              admissions, ps_verifications
echo ===========================================
echo.
echo 1. Show all users
echo 2. Check designations
echo 3. Check nationalities
echo 4. View admissions
echo 5. View PS verifications
echo 6. Show recent activity (all tables)
echo 7. Count records in all tables
echo 8. Custom SQL query
echo 9. Exit
echo ===========================================
set /p choice="Enter your choice (1-9): "

if "%choice%"=="1" goto show_users
if "%choice%"=="2" goto show_designations
if "%choice%"=="3" goto show_nationalities
if "%choice%"=="4" goto show_admissions
if "%choice%"=="5" goto show_ps_verifications
if "%choice%"=="6" goto recent_activity
if "%choice%"=="7" goto count_all
if "%choice%"=="8" goto custom_query
if "%choice%"=="9" exit

:show_users
echo.
echo ALL USERS:
echo ----------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, created_at FROM users ORDER BY created_at DESC;"
echo.
pause
goto menu

:show_designations
echo.
echo DESIGNATIONS:
echo -------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT * FROM designations ORDER BY id;"
echo.
pause
goto menu

:show_nationalities
echo.
echo NATIONALITIES:
echo --------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT * FROM nationalities ORDER BY id;"
echo.
pause
goto menu

:show_admissions
echo.
echo ADMISSIONS:
echo -----------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT * FROM admissions ORDER BY id DESC LIMIT 20;"
echo.
pause
goto menu

:show_ps_verifications
echo.
echo PS VERIFICATIONS:
echo -----------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT * FROM ps_verifications ORDER BY id DESC LIMIT 20;"
echo.
pause
goto menu

:recent_activity
echo.
echo RECENT ACTIVITY (Last 24 hours):
echo --------------------------------
echo.
echo Recent Users:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'USER: ' || username || ' (Role: ' || role || ') created at ' || created_at FROM users WHERE created_at > NOW() - INTERVAL '24 hours';"
echo.
echo Recent Updates:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'USER: ' || username || ' updated at ' || updated_at FROM users WHERE updated_at > NOW() - INTERVAL '24 hours' AND updated_at != created_at;"
echo.
pause
goto menu

:count_all
echo.
echo RECORD COUNTS:
echo --------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'Users' as table_name, COUNT(*) as count FROM users UNION ALL SELECT 'Designations', COUNT(*) FROM designations UNION ALL SELECT 'Nationalities', COUNT(*) FROM nationalities UNION ALL SELECT 'Admissions', COUNT(*) FROM admissions UNION ALL SELECT 'PS Verifications', COUNT(*) FROM ps_verifications;"
echo.
pause
goto menu

:custom_query
echo.
echo Enter your SQL query (or type 'back' to return):
set /p query="SQL> "
if /i "%query%"=="back" goto menu
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "%query%"
echo.
pause
goto menu