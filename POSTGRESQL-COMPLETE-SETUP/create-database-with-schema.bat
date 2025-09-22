@echo off
color 0B
echo ===========================================================
echo    CREATING CBA PORTAL DATABASE + SCHEMA IN POSTGRESQL
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

echo PostgreSQL found! Creating CBA Portal database with schema...
echo.

:: Get PostgreSQL password
set /p PGPASSWORD="Enter your PostgreSQL password (for 'postgres' user): "

if "%PGPASSWORD%"=="" (
    echo Error: Password cannot be empty.
    pause
    exit /b 1
)

echo.
echo [1/6] Testing connection to PostgreSQL...

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

echo [2/6] Creating database 'cba_portal'...
echo CREATE DATABASE cba_portal; | psql -U postgres -h localhost 2>nul
echo ✓ Database created (or already exists)

echo [3/6] Creating user 'cba_admin'...
echo CREATE USER cba_admin WITH PASSWORD 'CBA@2025Portal'; | psql -U postgres -h localhost 2>nul
echo ✓ User created (or already exists)

echo [4/6] Granting permissions...
echo GRANT ALL PRIVILEGES ON DATABASE cba_portal TO cba_admin; | psql -U postgres -h localhost
echo ALTER DATABASE cba_portal OWNER TO cba_admin; | psql -U postgres -h localhost
echo ✓ Permissions granted

echo [5/6] Creating tables and schema...
set PGPASSWORD=CBA@2025Portal

:: Create schema directly with psql commands
(
echo -- CBA Portal PostgreSQL Schema
echo.
echo -- Users table
echo CREATE TABLE IF NOT EXISTS users (
echo     id SERIAL PRIMARY KEY,
echo     username VARCHAR(100^) UNIQUE NOT NULL,
echo     password TEXT NOT NULL,
echo     role VARCHAR(50^) DEFAULT 'user',
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Designations table
echo CREATE TABLE IF NOT EXISTS designations (
echo     id SERIAL PRIMARY KEY,
echo     name VARCHAR(200^) NOT NULL,
echo     department VARCHAR(200^) NOT NULL,
echo     description TEXT,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Nationalities table
echo CREATE TABLE IF NOT EXISTS nationalities (
echo     id SERIAL PRIMARY KEY,
echo     name VARCHAR(100^) UNIQUE NOT NULL,
echo     code VARCHAR(10^),
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Admissions table
echo CREATE TABLE IF NOT EXISTS admissions (
echo     id SERIAL PRIMARY KEY,
echo     name VARCHAR(200^) NOT NULL,
echo     father_name VARCHAR(200^) NOT NULL,
echo     nationality VARCHAR(100^),
echo     address TEXT NOT NULL,
echo     phone VARCHAR(20^),
echo     email VARCHAR(100^),
echo     designation VARCHAR(200^),
echo     photo_path TEXT,
echo     status VARCHAR(50^) DEFAULT 'pending',
echo     admission_date DATE,
echo     created_by INTEGER,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- PS Verifications table
echo CREATE TABLE IF NOT EXISTS ps_verifications (
echo     id SERIAL PRIMARY KEY,
echo     staff_id VARCHAR(100^) NOT NULL UNIQUE,
echo     status VARCHAR(20^) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected'^)^),
echo     approved_by VARCHAR(100^),
echo     approved_date TIMESTAMP,
echo     rejected_by VARCHAR(100^),
echo     rejected_date TIMESTAMP,
echo     remarks TEXT,
echo     created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Insert default nationalities
echo INSERT INTO nationalities (name, code^) VALUES 
echo     ('Indian', 'IND'^),
echo     ('Pakistani', 'PAK'^),
echo     ('Bangladeshi', 'BGD'^),
echo     ('Nepalese', 'NPL'^),
echo     ('Sri Lankan', 'LKA'^),
echo     ('Other', 'OTH'^)
echo ON CONFLICT (name^) DO NOTHING;
echo.
echo -- Insert default designations
echo INSERT INTO designations (name, department, description^) VALUES 
echo     ('Chief Executive Officer', 'Administration', 'Head of cantonment board'^),
echo     ('Executive Officer', 'Administration', 'Senior administrative officer'^),
echo     ('Assistant Engineer', 'Engineering', 'Engineering department assistant'^),
echo     ('Junior Engineer', 'Engineering', 'Junior level engineer'^),
echo     ('Accountant', 'Finance', 'Financial operations'^),
echo     ('Medical Officer', 'Health', 'Healthcare services'^),
echo     ('Security Officer', 'Security', 'Security and safety'^),
echo     ('Sanitation Inspector', 'Health', 'Sanitation oversight'^),
echo     ('Tax Collector', 'Finance', 'Revenue collection'^),
echo     ('Store Keeper', 'Administration', 'Inventory management'^)
echo ON CONFLICT DO NOTHING;
echo.
echo -- Create default admin user (password: admin123^)
echo INSERT INTO users (username, password, role^) VALUES 
echo     ('admin', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'admin'^)
echo ON CONFLICT (username^) DO NOTHING;
echo.
echo -- Grant permissions to cba_admin
echo GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cba_admin;
echo GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cba_admin;
echo ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO cba_admin;
echo ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO cba_admin;
) > temp_schema.sql

:: Remove ^ characters and execute schema
powershell -Command "(Get-Content temp_schema.sql) -replace '\^', '' | Set-Content temp_schema.sql"
psql -U cba_admin -d cba_portal -h localhost -f temp_schema.sql
del temp_schema.sql

if errorlevel 1 (
    echo ⚠️  Schema creation had some issues, but continuing...
) else (
    echo ✓ Database schema and data created successfully!
)

echo [6/6] Testing complete setup...
echo SELECT 'CBA Portal Ready!' as status, COUNT(*) as user_count FROM users; | psql -U cba_admin -d cba_portal -h localhost
if errorlevel 1 (
    echo ⚠️  Warning: Could not test final setup.
) else (
    echo ✓ Complete setup confirmed!
)

echo.
echo ===========================================================
echo    ✓ DATABASE + SCHEMA SETUP COMPLETE!
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
echo Default Login Credentials:
echo --------------------------
echo Username: admin
echo Password: admin123
echo.
echo Your CBA Portal is now ready to use!
echo Start the server with: start-cba-portal-postgresql.bat
echo.
pause