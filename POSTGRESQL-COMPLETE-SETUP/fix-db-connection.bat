@echo off
echo ===========================================
echo PostgreSQL Connection Fix Tool
echo ===========================================
echo.

echo Current connection settings:
echo Host: localhost
echo Port: 5432
echo Database: cba_portal
echo User: postgres
echo.

echo Please enter the correct PostgreSQL password
echo (The password you set during PostgreSQL installation)
set /p PGPASSWORD="PostgreSQL Password: "

echo.
echo Testing connection...
psql -h localhost -p 5432 -d postgres -U postgres -c "SELECT version();" >nul 2>&1

if %errorlevel% equ 0 (
    echo SUCCESS! Connection established.
    echo.
    echo Updating all batch files with correct password...
    
    REM Create a file with the correct password
    echo @echo off > db-config.bat
    echo set PGPASSWORD=%PGPASSWORD% >> db-config.bat
    
    echo.
    echo Password saved to db-config.bat
    echo.
    echo Now updating the monitoring scripts...
    
    REM Update quick-db-check.bat
    powershell -Command "(gc quick-db-check.bat) -replace 'set PGPASSWORD=postgres', 'set PGPASSWORD=%PGPASSWORD%' | Out-File -encoding ASCII quick-db-check.bat"
    
    REM Update check-database-updates.bat
    powershell -Command "(gc check-database-updates.bat) -replace 'set PGPASSWORD=postgres', 'set PGPASSWORD=%PGPASSWORD%' | Out-File -encoding ASCII check-database-updates.bat"
    
    REM Update monitor-live-changes.bat
    powershell -Command "(gc monitor-live-changes.bat) -replace 'set PGPASSWORD=postgres', 'set PGPASSWORD=%PGPASSWORD%' | Out-File -encoding ASCII monitor-live-changes.bat"
    
    echo.
    echo All scripts updated successfully!
    echo.
    echo Testing database connection to cba_portal...
    psql -h localhost -p 5432 -d cba_portal -U postgres -c "SELECT 'Database cba_portal is accessible' as status;" 2>nul
    
    if %errorlevel% neq 0 (
        echo.
        echo WARNING: Cannot connect to cba_portal database.
        echo The database might not exist yet.
        echo.
        echo Would you like to create it? (Y/N)
        set /p create="Create database? "
        if /i "%create%"=="Y" (
            echo Creating database cba_portal...
            psql -h localhost -p 5432 -d postgres -U postgres -c "CREATE DATABASE cba_portal;"
            echo Database created successfully!
        )
    )
) else (
    echo.
    echo ERROR: Could not connect with the provided password.
    echo.
    echo Possible issues:
    echo 1. Wrong password - try the password you set during PostgreSQL installation
    echo 2. PostgreSQL service not running - check Windows Services
    echo 3. PostgreSQL not installed - install from POSTGRESQL-COMPLETE-SETUP folder
    echo.
    echo To check PostgreSQL service:
    echo   - Press Win+R, type 'services.msc'
    echo   - Look for 'postgresql-x64-17' service
    echo   - Make sure it's Running
)

echo.
pause