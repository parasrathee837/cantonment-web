@echo off
echo ===========================================
echo CBA Portal - Database Update Monitor
echo ===========================================
echo.

REM Set PostgreSQL connection parameters
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=postgres

REM Check PostgreSQL is running
echo Checking PostgreSQL service...
sc query postgresql-x64-17 >nul 2>&1
if %errorlevel% neq 0 (
    echo PostgreSQL service is not running!
    echo Please start PostgreSQL first.
    pause
    exit /b 1
)

echo PostgreSQL is running.
echo.

:menu
echo ===========================================
echo Select what you want to check:
echo ===========================================
echo 1. Show recent user activities (last 10 entries)
echo 2. Check user count
echo 3. Show recent logins
echo 4. Check recent staff additions
echo 5. View recent attendance records
echo 6. Check payslip generations
echo 7. View all tables with record counts
echo 8. Custom SQL query
echo 9. Exit
echo ===========================================
set /p choice="Enter your choice (1-9): "

if "%choice%"=="1" goto recent_activities
if "%choice%"=="2" goto user_count
if "%choice%"=="3" goto recent_logins
if "%choice%"=="4" goto recent_staff
if "%choice%"=="5" goto recent_attendance
if "%choice%"=="6" goto recent_payslips
if "%choice%"=="7" goto table_counts
if "%choice%"=="8" goto custom_query
if "%choice%"=="9" exit

:recent_activities
echo.
echo Recent User Activities:
echo -----------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT username, full_name, role, created_at, updated_at FROM users ORDER BY updated_at DESC LIMIT 10;"
echo.
pause
cls
goto menu

:user_count
echo.
echo Total Users in System:
echo ----------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT COUNT(*) as total_users FROM users;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT role, COUNT(*) as count FROM users GROUP BY role;"
echo.
pause
cls
goto menu

:recent_logins
echo.
echo Recent Login Activities:
echo ------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT u.username, u.full_name, u.last_login FROM users u WHERE u.last_login IS NOT NULL ORDER BY u.last_login DESC LIMIT 10;"
echo.
pause
cls
goto menu

:recent_staff
echo.
echo Recently Added Staff:
echo ---------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT username, full_name, mobile, role, created_at FROM users WHERE role != 'admin' ORDER BY created_at DESC LIMIT 10;"
echo.
pause
cls
goto menu

:recent_attendance
echo.
echo Recent Attendance Records:
echo --------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT u.username, u.full_name, a.date, a.status, a.created_at FROM attendance a JOIN users u ON a.user_id = u.id ORDER BY a.created_at DESC LIMIT 10;"
echo.
pause
cls
goto menu

:recent_payslips
echo.
echo Recent Payslip Generations:
echo ---------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT u.username, u.full_name, p.month, p.year, p.generated_at FROM payslips p JOIN users u ON p.user_id = u.id ORDER BY p.generated_at DESC LIMIT 10;"
echo.
pause
cls
goto menu

:table_counts
echo.
echo Record Counts for All Tables:
echo -----------------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT 'users' as table_name, COUNT(*) as count FROM users UNION ALL SELECT 'attendance', COUNT(*) FROM attendance UNION ALL SELECT 'payslips', COUNT(*) FROM payslips UNION ALL SELECT 'leaves', COUNT(*) FROM leaves UNION ALL SELECT 'designations', COUNT(*) FROM designations UNION ALL SELECT 'codes', COUNT(*) FROM codes UNION ALL SELECT 'files', COUNT(*) FROM files;"
echo.
pause
cls
goto menu

:custom_query
echo.
echo Enter your SQL query (or type 'back' to return to menu):
set /p query="SQL> "
if /i "%query%"=="back" (
    cls
    goto menu
)
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "%query%"
echo.
pause
cls
goto menu