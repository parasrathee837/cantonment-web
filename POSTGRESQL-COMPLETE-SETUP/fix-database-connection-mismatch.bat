@echo off
echo ===========================================
echo FIX DATABASE CONNECTION MISMATCH
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo MAJOR ISSUE FOUND:
echo ==================
echo Your .env file has database settings:
echo - DB_USER=cba_admin  
echo - DB_PASSWORD=CBA@2025Portal
echo.
echo But we've been connecting with:
echo - Username: postgres
echo - Password: CBA@2025Portal
echo.
echo This mismatch could cause the auth routes to fail!
echo.

echo Step 1: Test if cba_admin user exists in PostgreSQL
echo ===================================================

echo Testing connection with cba_admin user:
set PGUSER=cba_admin
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT current_user, current_database();" 2>nul

if %errorlevel% neq 0 (
    echo ERROR: cba_admin user doesn't exist or has wrong password!
    echo.
    echo This is why your auth routes return 500 errors.
    echo The backend tries to connect as cba_admin but fails.
    echo.
    
    echo Step 2: Create cba_admin user in PostgreSQL
    echo ===========================================
    set PGUSER=postgres
    echo Creating cba_admin user with proper permissions...
    
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "
    CREATE USER cba_admin WITH PASSWORD 'CBA@2025Portal';
    GRANT ALL PRIVILEGES ON DATABASE cba_portal TO cba_admin;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cba_admin;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cba_admin;
    ALTER USER cba_admin CREATEDB;
    "
    
    echo Testing cba_admin connection again:
    set PGUSER=cba_admin
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT current_user, current_database();"
    
) else (
    echo SUCCESS: cba_admin user exists and can connect!
)

echo.
echo Step 3: Test auth endpoints with correct database user
echo =====================================================

echo Testing admin login (backend should now use cba_admin):
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin123\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/login
echo.

echo Testing registration:
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"dbfixtest\",\"password\":\"password123\",\"full_name\":\"DB Fix Test\",\"email\":\"dbfix@test.com\",\"role\":\"user\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/register
echo.

echo Step 4: Check if user was created successfully
echo ==============================================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, email, role FROM users WHERE username = 'dbfixtest';"
echo.

echo Step 5: Alternative - Update .env to use postgres user
echo =======================================================
echo.
echo If creating cba_admin user doesn't work, you can modify your .env file:
echo.
echo Change these lines in backend/.env:
echo FROM: DB_USER=cba_admin
echo TO:   DB_USER=postgres
echo.
echo Then restart your server.
echo.

echo RESULTS INTERPRETATION:
echo =======================
echo.
echo If login/register work now (200/201 status):
echo ✅ Database connection fixed!
echo ✅ Auth endpoints working!
echo ✅ User creation should work!
echo.
echo If still getting 500 errors:
echo ❌ Check server console for specific error messages
echo ❌ There might be other missing tables or columns
echo.

pause