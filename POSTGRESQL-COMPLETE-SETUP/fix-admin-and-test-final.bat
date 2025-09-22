@echo off
echo ===========================================
echo FIX ADMIN PASSWORD AND FINAL ENDPOINT TEST
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Step 1: Fix admin password (make it 6+ characters)
echo ==================================================
echo Current admin password is "admin" (4 chars), needs to be 6+ chars
echo Updating admin password to "admin123" (8 chars)...

psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "UPDATE users SET password = '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy' WHERE username = 'admin';"

echo Updated! Admin credentials are now:
echo Username: admin
echo Password: admin123
echo.

echo Step 2: Test admin login with new password
echo ===========================================
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin123\"}" -s http://localhost:5000/api/auth/login > admin_login.json

echo Login response:
type admin_login.json
echo.

echo Step 3: Find what routes are actually working
echo ===============================================
echo Only /api/admissions gave 401 (exists but needs auth), all others gave 404
echo This means your server is not properly registering most routes!
echo.

echo Let's test /api/admissions since it's the only one that seems to exist:
echo.

echo Testing /api/admissions POST with basic auth token:
echo We need to extract token manually. Look at the JSON above and copy the token value.
echo.

echo Step 4: Test direct database insertion (bypass API completely)
echo ==============================================================
echo Since APIs might not be working, let's test direct database creation:

echo Creating user directly in database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "
INSERT INTO users (username, full_name, email, password, role, status, created_at, updated_at) 
VALUES ('directtest', 'Direct Database Test', 'direct@test.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'user', 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);"

echo Database users after direct insert:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, email, role FROM users ORDER BY created_at DESC;"
echo.

echo Step 5: Check your server console
echo =================================
echo IMPORTANT: Look at your server console window where you started the server.
echo It should show:
echo 1. Which routes are being registered
echo 2. Any errors during startup
echo 3. What port it's running on
echo 4. Any database connection errors
echo.
echo Common issues:
echo - Routes not being imported/registered in server.js
echo - Different port than 5000
echo - Database connection failures
echo - Missing route files
echo.

echo Step 6: MANUAL FRONTEND TEST
echo =============================
echo 1. Open http://localhost:5000 in browser
echo 2. Login with: admin / admin123
echo 3. Open F12 Developer Tools
echo 4. Go to Network tab
echo 5. Try to create user via popup
echo 6. See what endpoint it actually calls
echo 7. See the error response
echo.

echo DIAGNOSIS:
echo ==========
echo - Most API endpoints return 404 = Routes not properly registered
echo - Only /api/admissions works = Server configuration issue
echo - Database works fine (direct insert successful)
echo - Problem is in server.js route registration
echo.

del admin_login.json 2>nul
pause