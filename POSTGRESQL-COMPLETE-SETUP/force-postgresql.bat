@echo off
color 0A
echo ===========================================================
echo   FORCING POSTGRESQL DATABASE USAGE
echo ===========================================================
echo.

cd /d "C:\CBA_Portal\cantonment-web\backend"

echo Creating PostgreSQL-only .env file...
(
echo DB_TYPE=postgresql
echo DB_HOST=localhost
echo DB_PORT=5432
echo DB_NAME=cba_portal
echo DB_USER=cba_admin
echo DB_PASSWORD=CBA@2025Portal
echo PORT=5000
echo NODE_ENV=production
echo JWT_SECRET=cba-portal-postgresql-secret-2025
echo HOST=0.0.0.0
echo CORS_ORIGIN=*
) > .env

echo ✓ PostgreSQL .env file created

echo.
echo Checking .env content...
type .env

echo.
echo Testing PostgreSQL connection...
set PGPASSWORD=CBA@2025Portal
echo SELECT 'PostgreSQL Ready!' as status; | psql -U cba_admin -d cba_portal -h localhost 2>nul
if errorlevel 1 (
    echo.
    echo ⚠️  WARNING: PostgreSQL database not ready
    echo.
    echo You may need to create the database first.
    echo Run this command: create-database.bat
    echo.
    echo Press any key to continue anyway...
    pause >nul
) else (
    echo ✓ PostgreSQL connection working
)

echo.
echo ===========================================================
echo   STARTING SERVER WITH POSTGRESQL ONLY
echo ===========================================================
echo.
echo Database: PostgreSQL (cba_portal)
echo User: cba_admin
echo Server will start on port 5000
echo.
echo ⚠️  KEEP THIS WINDOW OPEN - Server runs here
echo.

echo Starting server with PostgreSQL...
node server.js

echo.
echo ===========================================================
echo   Server has stopped.
echo ===========================================================
pause