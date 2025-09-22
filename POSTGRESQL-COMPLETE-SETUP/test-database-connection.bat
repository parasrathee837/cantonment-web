@echo off
color 0A
echo ===========================================================
echo   TEST POSTGRESQL DATABASE CONNECTION
===========================================================
echo.

:: Set password
set PGPASSWORD=CBA@2025Portal

echo Testing connection to CBA Portal database...
echo.
echo Database Details:
echo -----------------
echo Server: localhost:5432
echo Database: cba_portal
echo Username: cba_admin
echo Password: CBA@2025Portal
echo.

echo [1/5] Testing PostgreSQL service...
sc query postgresql-x64-15 >nul 2>&1 || sc query postgresql-x64-16 >nul 2>&1
if errorlevel 1 (
    echo ❌ PostgreSQL service not found!
    echo Please install PostgreSQL first.
    pause
    exit /b 1
) else (
    echo ✓ PostgreSQL service found
)

echo [2/5] Testing basic connection...
echo SELECT version(); | psql -U postgres -h localhost >nul 2>&1
if errorlevel 1 (
    echo ❌ Cannot connect to PostgreSQL server!
    echo Check if PostgreSQL service is running.
    pause
    exit /b 1
) else (
    echo ✓ PostgreSQL server responding
)

echo [3/5] Testing CBA Portal database...
echo SELECT current_database(); | psql -U cba_admin -d cba_portal -h localhost >nul 2>&1
if errorlevel 1 (
    echo ❌ Cannot connect to cba_portal database!
    echo Please run create-database.bat first.
    pause
    exit /b 1
) else (
    echo ✓ CBA Portal database accessible
)

echo [4/5] Testing table structure...
echo \dt | psql -U cba_admin -d cba_portal -h localhost >nul 2>&1
if errorlevel 1 (
    echo ⚠️  No tables found (this is normal for new installation)
    echo Tables will be created when you first start the application.
) else (
    echo ✓ Database tables found
)

echo [5/5] Creating test entry...
(
echo CREATE TABLE IF NOT EXISTS connection_test (
echo   id SERIAL PRIMARY KEY,
echo   test_message TEXT,
echo   test_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo INSERT INTO connection_test (test_message^) 
echo VALUES ('Database connection test at ' ^|^| CURRENT_TIMESTAMP^);
echo.
echo SELECT * FROM connection_test ORDER BY id DESC LIMIT 5;
echo.
echo DROP TABLE connection_test;
) | psql -U cba_admin -d cba_portal -h localhost

if errorlevel 1 (
    echo ❌ Database read/write test failed!
) else (
    echo ✓ Database read/write test successful!
)

echo.
echo ===========================================================
echo   DATABASE CONNECTION TEST COMPLETED
echo ===========================================================
echo.

echo Summary:
echo --------
if not errorlevel 1 (
    echo ✓ PostgreSQL server: WORKING
    echo ✓ CBA Portal database: ACCESSIBLE
    echo ✓ Read/Write operations: SUCCESSFUL
    echo.
    echo Your database is ready for CBA Portal!
    echo.
    echo Next steps:
    echo 1. Start the server: start-cba-portal-postgresql.bat
    echo 2. Access portal: http://localhost:5000
    echo 3. Login with: admin / admin123
    echo.
    echo Database management:
    echo - pgAdmin 4: Start Menu → pgAdmin 4
    echo - Command line: psql -U cba_admin -d cba_portal
) else (
    echo ❌ Some tests failed. Please check the errors above.
    echo.
    echo Troubleshooting:
    echo 1. Make sure PostgreSQL is installed
    echo 2. Check if PostgreSQL service is running
    echo 3. Run create-database.bat to set up database
    echo 4. Verify credentials are correct
)

echo.
pause