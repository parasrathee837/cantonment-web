@echo off
echo ===========================================
echo FIX DATABASE SCHEMA ISSUES
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Current users table structure:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\d users"
echo.

echo Step 1: Add missing columns to users table
echo ==========================================

echo Adding full_name column:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS full_name VARCHAR(255);"

echo Adding email column:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255) UNIQUE;"

echo Adding phone column:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);"

echo Adding status column:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';"

echo Adding rights column:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS rights JSON;"

echo Adding last_login column:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP;"

echo Adding login_count column:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS login_count INTEGER DEFAULT 0;"

echo.
echo Updated users table structure:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\d users"
echo.

echo Step 2: Update admin user with missing data
echo ============================================
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "UPDATE users SET full_name = 'System Administrator', email = 'admin@cba.com', status = 'active' WHERE username = 'admin';"

echo Current users with new columns:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, full_name, email, role, status FROM users;"
echo.

echo Step 3: Create missing tables that admin.js expects
echo ===================================================

echo Creating user_profiles table:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "
CREATE TABLE IF NOT EXISTS user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    department VARCHAR(100),
    designation VARCHAR(100),
    employee_id VARCHAR(50),
    date_of_birth DATE,
    gender VARCHAR(10),
    address TEXT,
    emergency_contact VARCHAR(255),
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

echo Creating admin_actions table:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "
CREATE TABLE IF NOT EXISTS admin_actions (
    id SERIAL PRIMARY KEY,
    admin_user_id INTEGER REFERENCES users(id),
    action_type VARCHAR(50),
    target_entity VARCHAR(50),
    target_id VARCHAR(50),
    action_details JSON,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

echo.
echo Database schema fixed! Now testing user creation...
echo ===================================================

pause