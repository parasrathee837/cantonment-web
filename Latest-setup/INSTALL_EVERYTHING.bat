@echo off
echo ============================================
echo CBA PORTAL - COMPLETE INSTALLATION & SETUP
echo ============================================
echo.
echo This script will install and set up EVERYTHING:
echo 1. Check and install prerequisites (Node.js, PostgreSQL)
echo 2. Install all Node.js dependencies
echo 3. Create required directories
echo 4. Set up PostgreSQL database
echo 5. Install complete schema
echo 6. Configure backend
echo 7. Test everything works
echo.

set /p confirm="Continue with complete installation? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Installation cancelled.
    pause
    exit /b
)

echo.
echo ============================================
echo STEP 1: CHECKING PREREQUISITES
echo ============================================

echo Checking Node.js...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is NOT installed!
    echo.
    echo Please install Node.js from: https://nodejs.org/
    echo Download the LTS version (20.x or later)
    echo.
    echo After installing Node.js, run this script again.
    pause
    exit /b 1
) else (
    echo ✅ Node.js is installed:
    node --version
)

echo.
echo Checking npm...
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ npm is NOT installed!
    echo This should come with Node.js. Please reinstall Node.js.
    pause
    exit /b 1
) else (
    echo ✅ npm is installed:
    npm --version
)

echo.
echo Checking PostgreSQL...
psql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PostgreSQL is NOT installed or not in PATH!
    echo.
    echo Please install PostgreSQL from: https://www.postgresql.org/download/windows/
    echo - Download PostgreSQL 15 or later
    echo - During installation, remember the superuser password
    echo - Make sure to add PostgreSQL bin folder to PATH
    echo.
    echo After installing PostgreSQL, run this script again.
    pause
    exit /b 1
) else (
    echo ✅ PostgreSQL is installed:
    psql --version
)

echo.
echo Checking if PostgreSQL service is running...
sc query postgresql-x64-15 >nul 2>&1
if %errorlevel% neq 0 (
    sc query postgresql-x64-16 >nul 2>&1
    if %errorlevel% neq 0 (
        echo ⚠️  PostgreSQL service might not be running
        echo Trying to start PostgreSQL service...
        net start postgresql-x64-15 >nul 2>&1 || net start postgresql-x64-16 >nul 2>&1
        
        if %errorlevel% neq 0 (
            echo ❌ Could not start PostgreSQL service
            echo Please start it manually from Windows Services
            pause
            exit /b 1
        )
    )
)
echo ✅ PostgreSQL service is running

echo.
echo ============================================
echo STEP 2: CREATING REQUIRED DIRECTORIES
echo ============================================

echo Creating directory structure...
cd ..

if not exist "backend" mkdir backend
if not exist "backend\uploads" mkdir backend\uploads
if not exist "backend\uploads\profiles" mkdir backend\uploads\profiles
if not exist "backend\uploads\documents" mkdir backend\uploads\documents

echo ✅ Directories created

echo.
echo ============================================
echo STEP 3: INSTALLING NODE.JS DEPENDENCIES
echo ============================================

cd backend

echo Checking if package.json exists...
if not exist "package.json" (
    echo Creating package.json...
    echo {> package.json
    echo   "name": "cba-portal-backend",>> package.json
    echo   "version": "1.0.0",>> package.json
    echo   "description": "Cantonment Board Ambala Portal Backend",>> package.json
    echo   "main": "server.js",>> package.json
    echo   "scripts": {>> package.json
    echo     "start": "node server.js",>> package.json
    echo     "dev": "nodemon server.js">> package.json
    echo   }>> package.json
    echo }>> package.json
)

echo.
echo Installing required dependencies...
echo This may take a few minutes...
echo.

echo Installing core dependencies...
call npm install express cors helmet dotenv bcryptjs jsonwebtoken multer express-validator express-rate-limit

echo Installing database dependencies...
call npm install sqlite3 pg pg-hstore

echo Installing development dependencies...
call npm install --save-dev nodemon

echo ✅ All Node.js dependencies installed!

echo.
echo ============================================
echo STEP 4: POSTGRESQL DATABASE SETUP
echo ============================================

cd ..\Latest-setup

echo.
set /p pgpass="Enter PostgreSQL superuser (postgres) password: "
echo.

echo Creating database and user...
psql -U postgres -h localhost -p 5432 -c "DROP DATABASE IF EXISTS cba_portal;" 2>nul
psql -U postgres -h localhost -p 5432 -c "DROP USER IF EXISTS cba_admin;" 2>nul
psql -U postgres -h localhost -p 5432 -c "CREATE DATABASE cba_portal;"
psql -U postgres -h localhost -p 5432 -c "CREATE USER cba_admin WITH PASSWORD 'CBA@2025Portal';"
psql -U postgres -h localhost -p 5432 -c "GRANT ALL PRIVILEGES ON DATABASE cba_portal TO cba_admin;"
psql -U postgres -h localhost -p 5432 -c "ALTER USER cba_admin CREATEDB;"

echo.
echo Testing database connection...
set PGPASSWORD=CBA@2025Portal
psql -U cba_admin -h localhost -p 5432 -d cba_portal -c "SELECT current_user, current_database();"

if %errorlevel% neq 0 (
    echo ❌ Database connection failed!
    echo Please check your PostgreSQL installation and password.
    pause
    exit /b 1
)

echo ✅ Database created successfully!

echo.
echo ============================================
echo STEP 5: INSTALLING DATABASE SCHEMA
echo ============================================

echo Installing clean schema with all tables...
psql -U cba_admin -h localhost -p 5432 -d cba_portal -f "CLEAN_COMPLETE_SCHEMA.sql"

if %errorlevel% neq 0 (
    echo ❌ Schema installation failed!
    pause
    exit /b 1
)

echo ✅ Schema installed successfully!

echo.
echo Verifying installation...
psql -U cba_admin -h localhost -p 5432 -d cba_portal -c "SELECT COUNT(*) as total_tables FROM information_schema.tables WHERE table_schema = 'public';"
psql -U cba_admin -h localhost -p 5432 -d cba_portal -c "SELECT username, full_name, email, role FROM users WHERE username = 'admin';"

echo.
echo ============================================
echo STEP 6: BACKEND CONFIGURATION
echo ============================================

cd ..\backend

if exist ".env" (
    echo Backing up existing .env file...
    copy .env .env.backup.%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2% >nul
)

echo Creating .env configuration file...
echo PORT=5000> .env
echo JWT_SECRET=cba_cantonment_board_secret_key_2024_secure_token_ambala>> .env
echo NODE_ENV=development>> .env
echo UPLOAD_PATH=./uploads>> .env
echo MAX_FILE_SIZE=5242880>> .env
echo.>> .env
echo # PostgreSQL Database Configuration>> .env
echo DB_TYPE=postgresql>> .env
echo DB_HOST=localhost>> .env
echo DB_PORT=5432>> .env
echo DB_NAME=cba_portal>> .env
echo DB_USER=cba_admin>> .env
echo DB_PASSWORD=CBA@2025Portal>> .env

echo ✅ Backend configured!

echo.
echo ============================================
echo STEP 7: STARTING BACKEND SERVER
echo ============================================

echo Starting backend server...
echo.
echo ⚠️  IMPORTANT: A new window will open with the server.
echo     Keep that window open while using the application!
echo.

start "CBA Backend Server" cmd /k "node server.js"

echo Waiting for server to start...
timeout /t 5 >nul

echo.
echo ============================================
echo STEP 8: TESTING EVERYTHING WORKS
echo ============================================

cd ..\Latest-setup

echo Testing server health...
curl -s http://localhost:5000/api/health
echo.

echo Testing admin login...
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin123\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/login
echo.

echo.
echo ============================================
echo ✅ INSTALLATION COMPLETE!
echo ============================================
echo.
echo Installed:
echo ✅ PostgreSQL database: cba_portal
echo ✅ Database user: cba_admin
echo ✅ All Node.js dependencies
echo ✅ Complete database schema
echo ✅ Backend server running
echo.
echo Access the application:
echo 🌐 URL: http://localhost:5000
echo 👤 Username: admin
echo 🔑 Password: admin123
echo.
echo Backend server is running in a separate window.
echo DO NOT close that window while using the application!
echo.
echo TROUBLESHOOTING:
echo - If you see "Cannot find module" errors: Run npm install again
echo - If database errors: Check PostgreSQL service is running
echo - If port 5000 is busy: Change PORT in backend/.env file
echo.
echo Run TEST_DATA_FLOW.bat to verify everything works correctly.
echo.

pause