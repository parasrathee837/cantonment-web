@echo off
echo ===========================================
echo DEBUG AUTH SERVER ERRORS (500 ERRORS)
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo CRITICAL ISSUE FOUND:
echo =====================
echo Both /api/auth/login and /api/auth/register return "Server error" (500)
echo This means the backend routes have errors, not validation issues.
echo.
echo Likely causes:
echo 1. Database table structure mismatch
echo 2. Missing required tables that auth routes expect
echo 3. Database query syntax errors
echo.

echo Step 1: Check what tables auth-enhanced.js expects
echo ==================================================
echo.
echo Based on the auth-enhanced.js code, it expects these tables:
echo - users (with specific columns)
echo - login_attempts
echo - user_sessions  
echo - user_login_history
echo.

echo Let's check if these tables exist:
echo.

echo Checking users table structure:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\d users"
echo.

echo Checking if login_attempts table exists:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\d login_attempts" 2>nul || echo "login_attempts table MISSING"
echo.

echo Checking if user_sessions table exists:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\d user_sessions" 2>nul || echo "user_sessions table MISSING"
echo.

echo Checking if user_login_history table exists:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\d user_login_history" 2>nul || echo "user_login_history table MISSING"
echo.

echo Step 2: Create missing tables that auth-enhanced.js needs
echo =========================================================

echo Creating login_attempts table:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "
CREATE TABLE IF NOT EXISTS login_attempts (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    success BOOLEAN DEFAULT FALSE,
    user_id INTEGER,
    failure_reason VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

echo Creating user_sessions table:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "
CREATE TABLE IF NOT EXISTS user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    session_token TEXT UNIQUE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);"

echo Creating user_login_history table:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "
CREATE TABLE IF NOT EXISTS user_login_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_info JSON,
    login_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

echo.
echo Step 3: Test auth endpoints after creating missing tables
echo =========================================================

echo Testing admin login again:
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin123\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/login
echo.

echo Testing registration again:
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"finaltest\",\"password\":\"password123\",\"full_name\":\"Final Test User\",\"email\":\"final@test.com\",\"role\":\"user\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/register
echo.

echo Step 4: Check if users were created
echo ===================================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, email, role, created_at FROM users WHERE username = 'finaltest';"
echo.

echo Step 5: If still getting 500 errors, check server console
echo ==========================================================
echo.
echo IMPORTANT: Look at your server console window for error messages.
echo Common errors you might see:
echo - "Cannot find column 'xyz' in table 'users'"
echo - "Table 'xyz' doesn't exist"
echo - "JWT_SECRET is not defined"
echo - Database connection errors
echo.

echo If you see database-related errors, the table structures don't match what the code expects.
echo If you see JWT errors, check your .env file for JWT_SECRET.
echo.

echo NEXT STEPS:
echo ===========
echo 1. If login/register work now, you're all set!
echo 2. If still 500 errors, check server console for exact error messages
echo 3. Copy any error messages you see and we can fix them specifically
echo.

pause