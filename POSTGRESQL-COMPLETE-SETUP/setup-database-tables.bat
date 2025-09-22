@echo off
echo ===========================================
echo CBA Portal - Database Tables Setup
echo Self-contained installer
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Checking database connection...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT version();" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Cannot connect to database!
    echo Please check your connection settings.
    pause
    exit /b 1
)

echo Connection successful!
echo.
echo Current tables in database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT COUNT(*) || ' tables found' FROM information_schema.tables WHERE table_schema = 'public';"
echo.

echo This will add all missing tables for CBA Portal.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" exit /b 0

echo.
echo Creating database tables...

REM Create temporary SQL file with all commands
(
echo -- CBA Portal Essential Tables
echo.
echo -- User complete profile table
echo CREATE TABLE IF NOT EXISTS user_complete_profile ^(
echo     id SERIAL PRIMARY KEY,
echo     username VARCHAR^(100^) UNIQUE NOT NULL,
echo     password VARCHAR^(255^) NOT NULL,
echo     full_name VARCHAR^(100^),
echo     email VARCHAR^(100^),
echo     mobile VARCHAR^(15^),
echo     role VARCHAR^(20^) DEFAULT 'user',
echo     status VARCHAR^(20^) DEFAULT 'active',
echo     employee_id VARCHAR^(50^) UNIQUE,
echo     designation VARCHAR^(100^),
echo     department VARCHAR^(100^),
echo     date_of_joining DATE,
echo     date_of_birth DATE,
echo     gender VARCHAR^(10^),
echo     marital_status VARCHAR^(20^),
echo     nationality VARCHAR^(50^) DEFAULT 'Indian',
echo     permanent_address TEXT,
echo     communication_address TEXT,
echo     emergency_contact VARCHAR^(15^),
echo     emergency_contact_name VARCHAR^(100^),
echo     aadhar_number VARCHAR^(12^),
echo     pan_number VARCHAR^(10^),
echo     bank_name VARCHAR^(100^),
echo     account_number VARCHAR^(20^),
echo     ifsc_code VARCHAR^(11^),
echo     profile_photo VARCHAR^(255^),
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     last_login TIMESTAMP
echo ^);
echo.
echo -- Attendance table
echo CREATE TABLE IF NOT EXISTS attendance ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     date DATE NOT NULL,
echo     status VARCHAR^(20^) NOT NULL,
echo     check_in_time TIME,
echo     check_out_time TIME,
echo     overtime_hours DECIMAL^(4,2^),
echo     remarks TEXT,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Leave management
echo CREATE TABLE IF NOT EXISTS leaves ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     leave_type VARCHAR^(50^) NOT NULL,
echo     start_date DATE NOT NULL,
echo     end_date DATE NOT NULL,
echo     reason TEXT,
echo     status VARCHAR^(20^) DEFAULT 'pending',
echo     approved_by INTEGER,
echo     approved_at TIMESTAMP,
echo     remarks TEXT,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Payslips
echo CREATE TABLE IF NOT EXISTS payslips ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     month INTEGER NOT NULL,
echo     year INTEGER NOT NULL,
echo     basic_salary DECIMAL^(10,2^),
echo     da DECIMAL^(10,2^),
echo     hra DECIMAL^(10,2^),
echo     ta DECIMAL^(10,2^),
echo     medical_allowance DECIMAL^(10,2^),
echo     special_allowance DECIMAL^(10,2^),
echo     other_allowances DECIMAL^(10,2^),
echo     gross_salary DECIMAL^(10,2^),
echo     pf DECIMAL^(10,2^),
echo     professional_tax DECIMAL^(10,2^),
echo     income_tax DECIMAL^(10,2^),
echo     other_deductions DECIMAL^(10,2^),
echo     total_deductions DECIMAL^(10,2^),
echo     net_salary DECIMAL^(10,2^),
echo     payment_date DATE,
echo     payment_mode VARCHAR^(50^),
echo     generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     generated_by INTEGER
echo ^);
echo.
echo -- Function and Object Codes
echo CREATE TABLE IF NOT EXISTS codes ^(
echo     id SERIAL PRIMARY KEY,
echo     code_type VARCHAR^(50^) NOT NULL,
echo     code VARCHAR^(20^) NOT NULL,
echo     description VARCHAR^(255^),
echo     is_active BOOLEAN DEFAULT true,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     UNIQUE^(code_type, code^)
echo ^);
echo.
echo -- File uploads
echo CREATE TABLE IF NOT EXISTS files ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     file_name VARCHAR^(255^) NOT NULL,
echo     file_path VARCHAR^(500^) NOT NULL,
echo     file_type VARCHAR^(50^),
echo     file_size INTEGER,
echo     category VARCHAR^(50^),
echo     uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     uploaded_by INTEGER
echo ^);
echo.
echo -- Notifications
echo CREATE TABLE IF NOT EXISTS notifications ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     title VARCHAR^(200^) NOT NULL,
echo     message TEXT NOT NULL,
echo     type VARCHAR^(20^) DEFAULT 'info',
echo     is_read BOOLEAN DEFAULT false,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Audit logs
echo CREATE TABLE IF NOT EXISTS audit_logs ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     action VARCHAR^(50^) NOT NULL,
echo     entity_type VARCHAR^(50^),
echo     entity_id INTEGER,
echo     old_values TEXT,
echo     new_values TEXT,
echo     ip_address VARCHAR^(45^),
echo     user_agent TEXT,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Settings
echo CREATE TABLE IF NOT EXISTS settings ^(
echo     id SERIAL PRIMARY KEY,
echo     setting_key VARCHAR^(100^) UNIQUE NOT NULL,
echo     setting_value TEXT,
echo     setting_type VARCHAR^(50^),
echo     description TEXT,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Create indexes
echo CREATE INDEX IF NOT EXISTS idx_attendance_user_date ON attendance^(user_id, date^);
echo CREATE INDEX IF NOT EXISTS idx_leaves_user_status ON leaves^(user_id, status^);
echo CREATE INDEX IF NOT EXISTS idx_payslips_user_month_year ON payslips^(user_id, month, year^);
echo.
echo -- Insert default codes
echo INSERT INTO codes ^(code_type, code, description^) VALUES 
echo ^('function', 'ADM', 'Administration'^),
echo ^('function', 'FIN', 'Finance'^),
echo ^('function', 'HR', 'Human Resources'^),
echo ^('function', 'IT', 'Information Technology'^),
echo ^('function', 'SEC', 'Security'^),
echo ^('object', 'SAL', 'Salary'^),
echo ^('object', 'BEN', 'Benefits'^),
echo ^('object', 'TRV', 'Travel'^),
echo ^('object', 'OFF', 'Office Expenses'^),
echo ^('object', 'MAI', 'Maintenance'^)
echo ON CONFLICT DO NOTHING;
echo.
echo -- Copy existing users to user_complete_profile
echo INSERT INTO user_complete_profile ^(username, password, role, created_at, updated_at^)
echo SELECT username, password, role, created_at, updated_at 
echo FROM users 
echo WHERE NOT EXISTS ^(
echo     SELECT 1 FROM user_complete_profile ucp WHERE ucp.username = users.username
echo ^);
) > temp_schema.sql

echo Applying schema...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -f temp_schema.sql

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS! All tables created.
    del temp_schema.sql
    echo.
    echo Verifying installation...
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT COUNT(*) || ' total tables now in database' FROM information_schema.tables WHERE table_schema = 'public';"
    echo.
    echo Key tables created:
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT '- ' || table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('user_complete_profile', 'attendance', 'payslips', 'leaves', 'codes') ORDER BY table_name;"
    echo.
    echo Your database is now ready!
    echo Staff created through admin portal will be properly saved.
) else (
    echo.
    echo ERROR: Failed to create tables!
    echo Check temp_schema.sql for issues.
)

echo.
pause