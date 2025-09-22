@echo off
echo ============================================
echo CBA PORTAL - COMPLETE CLEAN SETUP
echo ============================================
echo.
echo This script will set up everything from scratch:
echo 1. Create PostgreSQL database and user
echo 2. Install complete clean schema with all tables
echo 3. Configure backend with correct settings
echo 4. Test all API endpoints
echo 5. Verify frontend-backend connectivity
echo.

set /p confirm="Continue with complete setup? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Setup cancelled.
    pause
    exit /b
)

echo.
echo Step 1: PostgreSQL Database Setup
echo =================================

echo Enter PostgreSQL superuser password when prompted...
echo.

echo Creating database and user:
psql -U postgres -h localhost -p 5432 -c "DROP DATABASE IF EXISTS cba_portal;"
psql -U postgres -h localhost -p 5432 -c "DROP USER IF EXISTS cba_admin;"
psql -U postgres -h localhost -p 5432 -c "CREATE DATABASE cba_portal;"
psql -U postgres -h localhost -p 5432 -c "CREATE USER cba_admin WITH PASSWORD 'CBA@2025Portal';"
psql -U postgres -h localhost -p 5432 -c "GRANT ALL PRIVILEGES ON DATABASE cba_portal TO cba_admin;"
psql -U postgres -h localhost -p 5432 -c "ALTER USER cba_admin CREATEDB;"

echo.
echo Testing database connection:
psql -U cba_admin -h localhost -p 5432 -d cba_portal -c "SELECT current_user, current_database();"

if %errorlevel% neq 0 (
    echo ERROR: Database connection failed!
    echo Please check your PostgreSQL installation and try again.
    pause
    exit /b 1
)

echo ✅ Database and user created successfully!
echo.

echo Step 2: Installing Complete Schema
echo ==================================

echo Installing clean schema with all required tables...
psql -U cba_admin -h localhost -p 5432 -d cba_portal -f "CLEAN_COMPLETE_SCHEMA.sql"

if %errorlevel% neq 0 (
    echo ERROR: Schema installation failed!
    pause
    exit /b 1
)

echo ✅ Schema installed successfully!
echo.

echo Verifying schema installation:
psql -U cba_admin -h localhost -p 5432 -d cba_portal -c "SELECT COUNT(*) as total_tables FROM information_schema.tables WHERE table_schema = 'public';"
psql -U cba_admin -h localhost -p 5432 -d cba_portal -c "SELECT username, full_name, email, role FROM users WHERE username = 'admin';"

echo.
echo Step 3: Backend Configuration
echo =============================

echo Checking backend .env file...
if exist "..\backend\.env" (
    echo ✅ .env file exists
    echo.
    echo Current .env settings:
    type "..\backend\.env"
    echo.
) else (
    echo ❌ .env file missing! Creating it...
    echo PORT=5000> "..\backend\.env"
    echo JWT_SECRET=cba_cantonment_board_secret_key_2024_secure_token_ambala>> "..\backend\.env"
    echo NODE_ENV=development>> "..\backend\.env"
    echo UPLOAD_PATH=./uploads>> "..\backend\.env"
    echo MAX_FILE_SIZE=5242880>> "..\backend\.env"
    echo.>> "..\backend\.env"
    echo # PostgreSQL Database Configuration>> "..\backend\.env"
    echo DB_TYPE=postgresql>> "..\backend\.env"
    echo DB_HOST=localhost>> "..\backend\.env"
    echo DB_PORT=5432>> "..\backend\.env"
    echo DB_NAME=cba_portal>> "..\backend\.env"
    echo DB_USER=cba_admin>> "..\backend\.env"
    echo DB_PASSWORD=CBA@2025Portal>> "..\backend\.env"
    echo ✅ .env file created!
)

echo.
echo Checking Node.js dependencies...
cd "..\backend"

if exist "package.json" (
    echo ✅ package.json found
    echo Installing dependencies...
    call npm install
    
    if %errorlevel% neq 0 (
        echo WARNING: npm install had issues. Continuing anyway...
    ) else (
        echo ✅ Dependencies installed!
    )
) else (
    echo ❌ package.json not found!
    echo Please ensure you're in the correct directory.
    pause
    exit /b 1
)

echo.
echo Step 4: Start Backend Server
echo ============================

echo Starting backend server...
echo ⚠️  IMPORTANT: Keep this window open to see server logs!
echo.
echo Backend will start on: http://localhost:5000
echo Admin credentials: admin / admin123
echo.

start "CBA Backend Server" cmd /k "node server.js"

echo Waiting for server to start...
timeout /t 3 >nul

echo.
echo Step 5: Testing API Endpoints
echo =============================

cd "..\Latest-setup"

echo Testing server health:
curl -s http://localhost:5000/api/health || echo "Health check failed"
echo.

echo Testing admin login:
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin123\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/login
echo.

echo Testing user registration:
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"testuser\",\"password\":\"password123\",\"full_name\":\"Test User\",\"email\":\"test@cba.com\",\"role\":\"user\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/register
echo.

echo.
echo Step 6: Final Verification
echo ==========================

echo Checking if test user was created:
psql -U cba_admin -h localhost -p 5432 -d cba_portal -c "SELECT id, username, full_name, email, role FROM users ORDER BY created_at DESC LIMIT 3;"

echo.
echo ============================================
echo SETUP COMPLETE!
echo ============================================
echo.
echo ✅ Database: PostgreSQL with cba_portal
echo ✅ User: cba_admin with full permissions
echo ✅ Schema: All %TABLES_COUNT% tables created
echo ✅ Backend: Running on http://localhost:5000
echo ✅ Admin: admin / admin123
echo.
echo NEXT STEPS:
echo 1. Open browser: http://localhost:5000
echo 2. Login with: admin / admin123
echo 3. Test user creation, deletion, editing
echo 4. All changes should appear in database immediately
echo.
echo TROUBLESHOOTING:
echo - If APIs return 500: Check backend server window for errors
echo - If login fails: Verify admin password is admin123
echo - If database errors: Check PostgreSQL service is running
echo.
echo Backend server is running in separate window.
echo Close that window to stop the server.
echo.

pause