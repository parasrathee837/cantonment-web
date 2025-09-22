@echo off
echo ===========================================
echo PostgreSQL Connection Tester
echo ===========================================
echo.

echo Checking PostgreSQL service status...
sc query postgresql-x64-17 >nul 2>&1
if %errorlevel% equ 0 (
    sc query postgresql-x64-17 | find "RUNNING" >nul
    if %errorlevel% equ 0 (
        echo [OK] PostgreSQL service is running
    ) else (
        echo [ERROR] PostgreSQL service is installed but not running
        echo.
        echo Starting PostgreSQL service...
        net start postgresql-x64-17
    )
) else (
    echo [ERROR] PostgreSQL service not found
    echo Please install PostgreSQL from POSTGRESQL-COMPLETE-SETUP folder
    pause
    exit /b 1
)

echo.
echo Testing different passwords...
echo.

REM Test common passwords
set passwords="postgres" "admin" "password" "123456" "root" ""

for %%p in (%passwords%) do (
    set PGPASSWORD=%%~p
    echo Testing password: %%p
    psql -h localhost -p 5432 -d postgres -U postgres -c "SELECT 1;" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [SUCCESS] Password found: %%p
        echo.
        echo Saving to db-config.bat...
        echo @echo off > db-config.bat
        echo set PGPASSWORD=%%~p >> db-config.bat
        goto :found
    )
)

echo.
echo [FAILED] None of the common passwords worked.
echo.
echo Please run fix-db-connection.bat to enter your password manually.
pause
exit /b 1

:found
echo.
echo Now checking if cba_portal database exists...
psql -h localhost -p 5432 -d cba_portal -U postgres -c "SELECT 1;" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Database cba_portal exists
) else (
    echo [INFO] Database cba_portal does not exist
    echo Run setup-postgresql-database.bat from POSTGRESQL-COMPLETE-SETUP folder
)

echo.
echo Connection test complete!
pause