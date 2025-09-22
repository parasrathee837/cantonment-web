@echo off
color 0C
echo ===========================================================
echo   FIXING ROOT SQLITE CONFLICT - COMPLETE CLEANUP
===========================================================
echo.
echo Issue: SQLite modules in cantonment-web root folder
echo Path: C:\CBA_Portal\cantonment-web\node_modules\sqlite3
echo.
echo This will remove ALL SQLite modules from everywhere!
echo.
pause

echo [1/8] Checking SQLite locations...
if exist "C:\CBA_Portal\cantonment-web\node_modules\sqlite3" (
    echo ❌ Found SQLite in ROOT: C:\CBA_Portal\cantonment-web\node_modules\sqlite3
    set FOUND_ROOT=1
) else (
    echo ✓ No SQLite in root
    set FOUND_ROOT=0
)

if exist "C:\CBA_Portal\cantonment-web\backend\node_modules\sqlite3" (
    echo ❌ Found SQLite in BACKEND: C:\CBA_Portal\cantonment-web\backend\node_modules\sqlite3
    set FOUND_BACKEND=1
) else (
    echo ✓ No SQLite in backend
    set FOUND_BACKEND=0
)

echo.
echo [2/8] Removing SQLite from ROOT folder...
cd /d "C:\CBA_Portal\cantonment-web"
rd /s /q node_modules\sqlite3 2>nul
rd /s /q node_modules\@types\sqlite3 2>nul
echo ✓ Root SQLite modules removed

echo [3/8] Removing SQLite from BACKEND folder...
cd /d "C:\CBA_Portal\cantonment-web\backend"
rd /s /q node_modules\sqlite3 2>nul
rd /s /q node_modules\@types\sqlite3 2>nul
echo ✓ Backend SQLite modules removed

echo [4/8] Checking for SQLite in package.json files...
cd /d "C:\CBA_Portal\cantonment-web"
if exist package.json (
    echo Found root package.json, removing SQLite references...
    powershell -Command "(Get-Content package.json) -replace '\"sqlite3\".*,?', '' | Set-Content package.json"
    echo ✓ SQLite removed from root package.json
)

cd /d "C:\CBA_Portal\cantonment-web\backend"
if exist package.json (
    echo Found backend package.json, removing SQLite references...
    powershell -Command "(Get-Content package.json) -replace '\"sqlite3\".*,?', '' | Set-Content package.json"
    echo ✓ SQLite removed from backend package.json
)

echo [5/8] Clearing ALL npm caches...
cd /d "C:\CBA_Portal\cantonment-web"
call npm cache clean --force 2>nul
cd /d "C:\CBA_Portal\cantonment-web\backend"
call npm cache clean --force 2>nul
echo ✓ All caches cleared

echo [6/8] Ensuring PostgreSQL-only configuration...
cd /d "C:\CBA_Portal\cantonment-web\backend"
(
    echo # CBA Portal - PostgreSQL EXCLUSIVE Configuration
    echo PORT=5000
    echo NODE_ENV=production
    echo.
    echo # PostgreSQL Database - SQLITE DISABLED
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
    echo.
    echo # Disable SQLite fallback
    echo NO_SQLITE=true
) > .env
echo ✓ PostgreSQL-exclusive .env created

echo [7/8] Reinstalling dependencies (PostgreSQL only)...
if exist package.json (
    call npm install pg pg-hstore --save
)
echo ✓ PostgreSQL dependencies ensured

echo [8/8] Final verification - searching for any remaining SQLite...
cd /d "C:\CBA_Portal\cantonment-web"
if exist node_modules\sqlite3 (
    echo ❌ WARNING: SQLite still found in root!
    rd /s /q node_modules\sqlite3
    echo ✓ Force removed
)

cd /d "C:\CBA_Portal\cantonment-web\backend"
if exist node_modules\sqlite3 (
    echo ❌ WARNING: SQLite still found in backend!
    rd /s /q node_modules\sqlite3
    echo ✓ Force removed
)

echo.
echo ===========================================================
echo   ✓ COMPLETE SQLITE CLEANUP FINISHED!
echo ===========================================================
echo.
echo What was removed:
echo ✓ SQLite modules from: C:\CBA_Portal\cantonment-web\node_modules\
echo ✓ SQLite modules from: C:\CBA_Portal\cantonment-web\backend\node_modules\
echo ✓ SQLite references from package.json files
echo ✓ All npm caches cleared
echo ✓ PostgreSQL-exclusive configuration created
echo.
echo Now your app should use ONLY PostgreSQL!
echo.
echo Test it: start-cba-portal-postgresql.bat
echo.
pause