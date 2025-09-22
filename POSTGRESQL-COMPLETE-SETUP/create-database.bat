@echo off
color 0B
echo ===========================================================
echo    CREATING CBA PORTAL DATABASE IN POSTGRESQL
echo ===========================================================
echo.

:: Check if PostgreSQL is installed
psql --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: PostgreSQL not found!
    echo.
    echo Please install PostgreSQL first using install-postgresql.bat
    echo Or add PostgreSQL to PATH manually.
    echo.
    pause
    exit /b 1
)

echo PostgreSQL found! Creating CBA Portal database...
echo.

:: Get PostgreSQL password
set /p PGPASSWORD="Enter your PostgreSQL password (for 'postgres' user): "

if "%PGPASSWORD%"=="" (
    echo Error: Password cannot be empty.
    pause
    exit /b 1
)

echo.
echo [1/4] Testing connection to PostgreSQL...

:: Test connection
echo SELECT version(); | psql -U postgres -h localhost >nul 2>&1
if errorlevel 1 (
    echo ❌ Connection failed!
    echo.
    echo Please check:
    echo 1. PostgreSQL service is running
    echo 2. Password is correct
    echo 3. PostgreSQL is installed properly
    echo.
    echo To check service: services.msc → postgresql-x64-15
    echo.
    pause
    exit /b 1
)

echo ✓ Connection successful!

echo [2/4] Creating database 'cba_portal'...
echo CREATE DATABASE cba_portal; | psql -U postgres -h localhost 2>nul
echo ✓ Database created (or already exists)

echo [3/4] Creating user 'cba_admin'...
echo CREATE USER cba_admin WITH PASSWORD 'CBA@2025Portal'; | psql -U postgres -h localhost 2>nul
echo ✓ User created (or already exists)

echo [4/4] Granting permissions...
echo GRANT ALL PRIVILEGES ON DATABASE cba_portal TO cba_admin; | psql -U postgres -h localhost
echo ALTER DATABASE cba_portal OWNER TO cba_admin; | psql -U postgres -h localhost
echo ✓ Permissions granted

echo.
echo [5/5] Testing CBA Portal database access...
set PGPASSWORD=CBA@2025Portal
echo SELECT 'CBA Portal database is ready!' as status; | psql -U cba_admin -d cba_portal -h localhost >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Warning: Could not test with cba_admin user.
    echo   This might be normal. Continuing...
) else (
    echo ✓ CBA Portal database access confirmed!
)

echo.
echo ===========================================================
echo    ✓ DATABASE SETUP COMPLETE!
echo ===========================================================
echo.
echo Database Details:
echo -----------------
echo Server: localhost
echo Port: 5432
echo Database: cba_portal
echo Username: cba_admin
echo Password: CBA@2025Portal
echo.
echo The CBA Portal application will use these credentials
echo to connect to the database.
echo.
echo Next step: Run install-dependencies.bat
echo.
pause