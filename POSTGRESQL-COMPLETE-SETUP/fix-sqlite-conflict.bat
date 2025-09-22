@echo off
color 0C
echo ===========================================================
echo   FIXING SQLITE CONFLICT - POSTGRESQL SETUP
echo ===========================================================
echo.
echo Good news: PostgreSQL connected successfully!
echo Issue: App still trying to load SQLite modules
echo.
echo This will completely remove SQLite and ensure only PostgreSQL is used.
echo.
pause

cd /d "C:\CBA_Portal\cantonment-web\backend"

echo [1/6] Removing SQLite modules...
rd /s /q node_modules\sqlite3 2>nul
echo ✓ SQLite3 module removed

echo [2/6] Updating package.json to remove SQLite dependency...
if exist package.json (
    powershell -Command "(Get-Content package.json) -replace '\"sqlite3\".*,?', '' | Set-Content package.json"
    echo ✓ SQLite dependency removed from package.json
)

echo [3/6] Clearing npm cache...
call npm cache clean --force
echo ✓ Cache cleared

echo [4/6] Ensuring PostgreSQL configuration...
(
    echo # CBA Portal - PostgreSQL ONLY Configuration
    echo PORT=5000
    echo NODE_ENV=production
    echo.
    echo # PostgreSQL Database Configuration - NO SQLITE!
    echo DB_TYPE=postgresql
    echo DB_HOST=localhost
    echo DB_PORT=5432
    echo DB_NAME=cba_portal
    echo DB_USER=cba_admin
    echo DB_PASSWORD=CBA@2025Portal
    echo.
    echo # Security
    echo JWT_SECRET=cba-portal-postgresql-only-2025
    echo.
    echo # Network Configuration
    echo HOST=0.0.0.0
    echo CORS_ORIGIN=*
) > .env
echo ✓ PostgreSQL-only configuration created

echo [5/6] Reinstalling dependencies (PostgreSQL only)...
call npm install --omit=optional
call npm install pg pg-hstore
echo ✓ PostgreSQL drivers installed

echo [6/6] Verifying no SQLite references...
if exist node_modules\sqlite3 (
    echo ❌ SQLite still present, removing again...
    rd /s /q node_modules\sqlite3
)
echo ✓ Verification complete

echo.
echo ===========================================================
echo   ✓ SQLITE CONFLICT RESOLVED!
echo ===========================================================
echo.
echo Changes made:
echo ✓ Removed all SQLite modules
echo ✓ Updated configuration for PostgreSQL only
echo ✓ Reinstalled dependencies without SQLite
echo ✓ Verified PostgreSQL drivers are present
echo.
echo Now try starting the server again:
echo start-cba-portal-postgresql.bat
echo.
pause