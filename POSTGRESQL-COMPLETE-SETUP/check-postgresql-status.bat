@echo off
color 0B
echo ===========================================================
echo   POSTGRESQL STATUS CHECKER
===========================================================
echo.

echo [1/5] Checking if PostgreSQL is installed...

:: Method 1: Check PATH
psql --version >nul 2>&1
if not errorlevel 1 (
    echo ✓ PostgreSQL found in PATH
    for /f "tokens=*" %%i in ('psql --version') do echo   Version: %%i
    goto :check_service
)

:: Method 2: Check common installation paths
echo ⚠️  PostgreSQL not in PATH, checking installation folders...

if exist "C:\Program Files\PostgreSQL\15\bin\psql.exe" (
    echo ✓ PostgreSQL 15 found: C:\Program Files\PostgreSQL\15\
    set PGBIN=C:\Program Files\PostgreSQL\15\bin
    goto :path_fix
)

if exist "C:\Program Files\PostgreSQL\16\bin\psql.exe" (
    echo ✓ PostgreSQL 16 found: C:\Program Files\PostgreSQL\16\
    set PGBIN=C:\Program Files\PostgreSQL\16\bin
    goto :path_fix
)

if exist "C:\Program Files\PostgreSQL\14\bin\psql.exe" (
    echo ✓ PostgreSQL 14 found: C:\Program Files\PostgreSQL\14\
    set PGBIN=C:\Program Files\PostgreSQL\14\bin
    goto :path_fix
)

if exist "C:\Program Files\PostgreSQL\17\bin\psql.exe" (
    echo ✓ PostgreSQL 17 found: C:\Program Files\PostgreSQL\17\
    set PGBIN=C:\Program Files\PostgreSQL\17\bin
    goto :path_fix
)

echo ❌ PostgreSQL NOT INSTALLED!
echo.
echo SOLUTIONS:
echo 1. Run install-postgresql.bat (automatic)
echo 2. Download from: https://www.postgresql.org/download/windows/
echo.
goto :end

:path_fix
echo.
echo [2/5] PostgreSQL found but not in PATH. Fixing...
echo Adding to PATH: %PGBIN%
echo.
set PATH=%PATH%;%PGBIN%
echo ✓ PATH updated for this session
echo.
"%PGBIN%\psql.exe" --version
echo.
echo PERMANENT FIX: Run fix-postgresql-path.bat as administrator
echo.

:check_service
echo [3/5] Checking PostgreSQL service...

:: Check for different service names
sc query postgresql-x64-15 >nul 2>&1
if not errorlevel 1 (
    echo ✓ PostgreSQL 15 service found
    sc query postgresql-x64-15 | find "STATE"
    goto :check_connection
)

sc query postgresql-x64-16 >nul 2>&1
if not errorlevel 1 (
    echo ✓ PostgreSQL 16 service found
    sc query postgresql-x64-16 | find "STATE"
    goto :check_connection
)

sc query postgresql-x64-14 >nul 2>&1
if not errorlevel 1 (
    echo ✓ PostgreSQL 14 service found
    sc query postgresql-x64-14 | find "STATE"
    goto :check_connection
)

echo ⚠️  PostgreSQL service not found
echo Service might have different name or not installed properly
echo.

:check_connection
echo [4/5] Testing database server connection...

if defined PGBIN (
    set PGPASSWORD=postgres
    echo Testing connection... | "%PGBIN%\psql.exe" -U postgres -h localhost >nul 2>&1
) else (
    set PGPASSWORD=postgres
    echo Testing connection... | psql -U postgres -h localhost >nul 2>&1
)

if errorlevel 1 (
    echo ❌ Cannot connect to PostgreSQL server
    echo.
    echo Possible issues:
    echo - PostgreSQL service not running
    echo - Wrong password
    echo - PostgreSQL not properly installed
    echo.
    echo Try starting service:
    echo   net start postgresql-x64-15
    echo   (or postgresql-x64-16)
) else (
    echo ✓ PostgreSQL server responding
)

echo [5/5] Testing CBA Portal database...
set PGPASSWORD=CBA@2025Portal

if defined PGBIN (
    echo SELECT 'CBA Portal database test'; | "%PGBIN%\psql.exe" -U cba_admin -d cba_portal -h localhost >nul 2>&1
) else (
    echo SELECT 'CBA Portal database test'; | psql -U cba_admin -d cba_portal -h localhost >nul 2>&1
)

if errorlevel 1 (
    echo ❌ CBA Portal database not accessible
    echo Need to run: create-database.bat
) else (
    echo ✓ CBA Portal database accessible
)

:end
echo.
echo ===========================================================
echo   STATUS CHECK COMPLETE
echo ===========================================================
echo.

echo SUMMARY:
echo --------
if defined PGBIN (
    echo PostgreSQL: FOUND (but PATH needs fixing)
    echo Location: %PGBIN%
    echo.
    echo TO FIX:
    echo 1. Run fix-postgresql-path.bat as administrator
    echo 2. Or restart computer
    echo 3. Then continue with setup
) else (
    psql --version >nul 2>&1
    if not errorlevel 1 (
        echo PostgreSQL: WORKING
        echo Continue with your setup!
    ) else (
        echo PostgreSQL: NOT INSTALLED
        echo Run: install-postgresql.bat
    )
)

echo.
pause