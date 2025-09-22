@echo off
echo ===========================================
echo CBA Portal - Create ALL Missing Tables
echo Complete Database Schema Setup
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo This will create ALL tables required by the CBA Portal application.
echo.
set /p confirm="Continue with complete setup? (Y/N): "
if /i not "%confirm%"=="Y" exit /b 0

echo.
echo Creating comprehensive database schema...

REM Create the complete SQL schema
(
echo -- CBA Portal Complete Database Schema
echo -- Creates all tables required by the application
echo.
echo -- ======================
echo -- USER MANAGEMENT TABLES
echo -- ======================
echo.
echo -- Extended user profile with all fields
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
echo -- User profiles table
echo CREATE TABLE IF NOT EXISTS user_profiles ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     profile_data JSONB,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- User sessions
echo CREATE TABLE IF NOT EXISTS user_sessions ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     session_token VARCHAR^(255^) UNIQUE,
echo     ip_address VARCHAR^(45^),
echo     user_agent TEXT,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     expires_at TIMESTAMP,
echo     is_active BOOLEAN DEFAULT true
echo ^);
echo.
echo -- User activity logs
echo CREATE TABLE IF NOT EXISTS user_activity ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     action VARCHAR^(100^),
echo     details TEXT,
echo     ip_address VARCHAR^(45^),
echo     user_agent TEXT,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Login attempts tracking
echo CREATE TABLE IF NOT EXISTS login_attempts ^(
echo     id SERIAL PRIMARY KEY,
echo     username VARCHAR^(100^),
echo     ip_address VARCHAR^(45^),
echo     success BOOLEAN,
echo     attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- User login history
echo CREATE TABLE IF NOT EXISTS user_login_history ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     logout_time TIMESTAMP,
echo     ip_address VARCHAR^(45^),
echo     user_agent TEXT
echo ^);
echo.
echo -- ======================
echo -- STAFF/ADMISSION TABLES
echo -- ======================
echo.
echo -- Staff personal information
echo CREATE TABLE IF NOT EXISTS staff_personal ^(
echo     id SERIAL PRIMARY KEY,
echo     staff_id VARCHAR^(50^) UNIQUE,
echo     full_name VARCHAR^(100^),
echo     father_name VARCHAR^(100^),
echo     mother_name VARCHAR^(100^),
echo     date_of_birth DATE,
echo     gender VARCHAR^(10^),
echo     marital_status VARCHAR^(20^),
echo     nationality VARCHAR^(50^),
echo     permanent_address TEXT,
echo     communication_address TEXT,
echo     mobile VARCHAR^(15^),
echo     email VARCHAR^(100^),
echo     emergency_contact_name VARCHAR^(100^),
echo     emergency_contact_number VARCHAR^(15^),
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Staff banking information
echo CREATE TABLE IF NOT EXISTS staff_banking ^(
echo     id SERIAL PRIMARY KEY,
echo     staff_id VARCHAR^(50^),
echo     bank_name VARCHAR^(100^),
echo     account_number VARCHAR^(20^),
echo     ifsc_code VARCHAR^(11^),
echo     micr_code VARCHAR^(9^),
echo     account_type VARCHAR^(20^),
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Staff documents
echo CREATE TABLE IF NOT EXISTS staff_documents ^(
echo     id SERIAL PRIMARY KEY,
echo     staff_id VARCHAR^(50^),
echo     document_type VARCHAR^(50^),
echo     document_number VARCHAR^(50^),
echo     document_path VARCHAR^(500^),
echo     verified BOOLEAN DEFAULT false,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Staff salary information
echo CREATE TABLE IF NOT EXISTS staff_salary ^(
echo     id SERIAL PRIMARY KEY,
echo     staff_id VARCHAR^(50^),
echo     basic_pay DECIMAL^(10,2^),
echo     grade_pay DECIMAL^(10,2^),
echo     da_rate DECIMAL^(5,2^),
echo     hra_rate DECIMAL^(5,2^),
echo     ta_rate DECIMAL^(5,2^),
echo     medical_allowance DECIMAL^(10,2^),
echo     special_allowance DECIMAL^(10,2^),
echo     pay_level INTEGER,
echo     pay_band VARCHAR^(50^),
echo     effective_date DATE,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Staff deductions
echo CREATE TABLE IF NOT EXISTS staff_deductions ^(
echo     id SERIAL PRIMARY KEY,
echo     staff_id VARCHAR^(50^),
echo     deduction_type VARCHAR^(50^),
echo     amount DECIMAL^(10,2^),
echo     effective_date DATE,
echo     end_date DATE,
echo     is_active BOOLEAN DEFAULT true,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Comprehensive staff deductions
echo CREATE TABLE IF NOT EXISTS staff_deductions_comprehensive ^(
echo     id SERIAL PRIMARY KEY,
echo     staff_id VARCHAR^(50^),
echo     pf_amount DECIMAL^(10,2^),
echo     professional_tax DECIMAL^(10,2^),
echo     income_tax DECIMAL^(10,2^),
echo     loan_deduction DECIMAL^(10,2^),
echo     insurance_premium DECIMAL^(10,2^),
echo     other_deductions DECIMAL^(10,2^),
echo     month INTEGER,
echo     year INTEGER,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- ======================
echo -- ATTENDANCE TABLES
echo -- ======================
echo.
echo -- Basic attendance
echo CREATE TABLE IF NOT EXISTS attendance ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     staff_id VARCHAR^(50^),
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
echo -- Detailed attendance records
echo CREATE TABLE IF NOT EXISTS attendance_records ^(
echo     id SERIAL PRIMARY KEY,
echo     staff_id VARCHAR^(50^),
echo     date DATE,
echo     time_in TIME,
echo     time_out TIME,
echo     break_time INTEGER,
echo     overtime_minutes INTEGER,
echo     status VARCHAR^(20^),
echo     remarks TEXT,
echo     approved_by INTEGER,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Daily attendance summary
echo CREATE TABLE IF NOT EXISTS daily_attendance ^(
echo     id SERIAL PRIMARY KEY,
echo     date DATE,
echo     total_staff INTEGER,
echo     present_count INTEGER,
echo     absent_count INTEGER,
echo     leave_count INTEGER,
echo     half_day_count INTEGER,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Holidays calendar
echo CREATE TABLE IF NOT EXISTS holidays ^(
echo     id SERIAL PRIMARY KEY,
echo     date DATE UNIQUE,
echo     name VARCHAR^(100^),
echo     type VARCHAR^(50^),
echo     is_optional BOOLEAN DEFAULT false,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- ======================
echo -- LEAVE MANAGEMENT
echo -- ======================
echo.
echo -- Basic leaves table
echo CREATE TABLE IF NOT EXISTS leaves ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     staff_id VARCHAR^(50^),
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
echo -- Leave applications
echo CREATE TABLE IF NOT EXISTS leave_applications ^(
echo     id SERIAL PRIMARY KEY,
echo     staff_id VARCHAR^(50^),
echo     leave_type_id INTEGER,
echo     start_date DATE,
echo     end_date DATE,
echo     days_requested INTEGER,
echo     reason TEXT,
echo     status VARCHAR^(20^) DEFAULT 'pending',
echo     applied_date DATE DEFAULT CURRENT_DATE,
echo     approved_by INTEGER,
echo     approved_date DATE,
echo     rejection_reason TEXT,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Leave types
echo CREATE TABLE IF NOT EXISTS leave_types ^(
echo     id SERIAL PRIMARY KEY,
echo     name VARCHAR^(50^) UNIQUE,
echo     code VARCHAR^(10^) UNIQUE,
echo     max_days_per_year INTEGER,
echo     carry_forward BOOLEAN DEFAULT false,
echo     is_active BOOLEAN DEFAULT true,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- ======================
echo -- PAYROLL TABLES
echo -- ======================
echo.
echo -- Payslips
echo CREATE TABLE IF NOT EXISTS payslips ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     staff_id VARCHAR^(50^),
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
echo -- PS Verifications
echo CREATE TABLE IF NOT EXISTS ps_verifications ^(
echo     id SERIAL PRIMARY KEY,
echo     staff_id VARCHAR^(50^),
echo     verification_type VARCHAR^(50^),
echo     status VARCHAR^(20^) DEFAULT 'pending',
echo     submitted_date DATE,
echo     verified_date DATE,
echo     verified_by INTEGER,
echo     remarks TEXT,
echo     documents_path VARCHAR^(500^),
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- ======================
echo -- CODE TABLES
echo -- ======================
echo.
echo -- General codes table
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
echo -- Function codes
echo CREATE TABLE IF NOT EXISTS function_codes ^(
echo     id SERIAL PRIMARY KEY,
echo     code VARCHAR^(20^) UNIQUE,
echo     name VARCHAR^(100^),
echo     description TEXT,
echo     is_active BOOLEAN DEFAULT true,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Object codes
echo CREATE TABLE IF NOT EXISTS object_codes ^(
echo     id SERIAL PRIMARY KEY,
echo     code VARCHAR^(20^) UNIQUE,
echo     name VARCHAR^(100^),
echo     description TEXT,
echo     function_code_id INTEGER,
echo     is_active BOOLEAN DEFAULT true,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- ======================
echo -- SYSTEM TABLES
echo -- ======================
echo.
echo -- Files/Documents
echo CREATE TABLE IF NOT EXISTS files ^(
echo     id SERIAL PRIMARY KEY,
echo     user_id INTEGER,
echo     staff_id VARCHAR^(50^),
echo     file_name VARCHAR^(255^) NOT NULL,
echo     file_path VARCHAR^(500^) NOT NULL,
echo     file_type VARCHAR^(50^),
echo     file_size INTEGER,
echo     category VARCHAR^(50^),
echo     uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     uploaded_by INTEGER
echo ^);
echo.
echo -- Documents table
echo CREATE TABLE IF NOT EXISTS documents ^(
echo     id SERIAL PRIMARY KEY,
echo     title VARCHAR^(200^),
echo     description TEXT,
echo     file_path VARCHAR^(500^),
echo     document_type VARCHAR^(50^),
echo     uploaded_by INTEGER,
echo     uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     is_public BOOLEAN DEFAULT false
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
echo -- System errors
echo CREATE TABLE IF NOT EXISTS system_errors ^(
echo     id SERIAL PRIMARY KEY,
echo     error_type VARCHAR^(50^),
echo     error_message TEXT,
echo     stack_trace TEXT,
echo     user_id INTEGER,
echo     request_url VARCHAR^(500^),
echo     request_method VARCHAR^(10^),
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- ======================
echo -- ADMIN TABLES
echo -- ======================
echo.
echo -- Admin dashboard summary
echo CREATE TABLE IF NOT EXISTS admin_dashboard_summary ^(
echo     id SERIAL PRIMARY KEY,
echo     total_users INTEGER,
echo     active_users INTEGER,
echo     total_staff INTEGER,
echo     present_today INTEGER,
echo     pending_leaves INTEGER,
echo     generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Admin actions
echo CREATE TABLE IF NOT EXISTS admin_actions ^(
echo     id SERIAL PRIMARY KEY,
echo     admin_id INTEGER,
echo     action_type VARCHAR^(50^),
echo     target_type VARCHAR^(50^),
echo     target_id INTEGER,
echo     description TEXT,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- Admin settings
echo CREATE TABLE IF NOT EXISTS admin_settings ^(
echo     id SERIAL PRIMARY KEY,
echo     setting_category VARCHAR^(50^),
echo     setting_name VARCHAR^(100^),
echo     setting_value TEXT,
echo     updated_by INTEGER,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo ^);
echo.
echo -- ======================
echo -- INDEXES FOR PERFORMANCE
echo -- ======================
echo.
echo CREATE INDEX IF NOT EXISTS idx_attendance_staff_date ON attendance^(staff_id, date^);
echo CREATE INDEX IF NOT EXISTS idx_attendance_user_date ON attendance^(user_id, date^);
echo CREATE INDEX IF NOT EXISTS idx_leaves_staff_status ON leaves^(staff_id, status^);
echo CREATE INDEX IF NOT EXISTS idx_payslips_staff_month_year ON payslips^(staff_id, month, year^);
echo CREATE INDEX IF NOT EXISTS idx_user_activity_user_created ON user_activity^(user_id, created_at^);
echo CREATE INDEX IF NOT EXISTS idx_audit_logs_user_created ON audit_logs^(user_id, created_at^);
echo.
echo -- ======================
echo -- DEFAULT DATA
echo -- ======================
echo.
echo -- Insert default leave types
echo INSERT INTO leave_types ^(name, code, max_days_per_year^) VALUES 
echo ^('Casual Leave', 'CL', 12^),
echo ^('Sick Leave', 'SL', 12^),
echo ^('Earned Leave', 'EL', 30^),
echo ^('Maternity Leave', 'ML', 180^),
echo ^('Paternity Leave', 'PL', 15^)
echo ON CONFLICT ^(name^) DO NOTHING;
echo.
echo -- Insert default function codes
echo INSERT INTO codes ^(code_type, code, description^) VALUES 
echo ^('function', 'ADM', 'Administration'^),
echo ^('function', 'FIN', 'Finance'^),
echo ^('function', 'HR', 'Human Resources'^),
echo ^('function', 'IT', 'Information Technology'^),
echo ^('function', 'SEC', 'Security'^),
echo ^('function', 'MNT', 'Maintenance'^),
echo ^('object', 'SAL', 'Salary'^),
echo ^('object', 'BEN', 'Benefits'^),
echo ^('object', 'TRV', 'Travel'^),
echo ^('object', 'OFF', 'Office Expenses'^),
echo ^('object', 'MAI', 'Maintenance'^),
echo ^('object', 'EQP', 'Equipment'^)
echo ON CONFLICT ^(code_type, code^) DO NOTHING;
echo.
echo -- Insert common holidays
echo INSERT INTO holidays ^(date, name, type^) VALUES 
echo ^('2025-01-26', 'Republic Day', 'National'^),
echo ^('2025-08-15', 'Independence Day', 'National'^),
echo ^('2025-10-02', 'Gandhi Jayanti', 'National'^)
echo ON CONFLICT ^(date^) DO NOTHING;
echo.
echo -- Copy existing users to user_complete_profile
echo INSERT INTO user_complete_profile ^(username, password, role, created_at, updated_at^)
echo SELECT username, password, role, created_at, updated_at 
echo FROM users 
echo WHERE NOT EXISTS ^(
echo     SELECT 1 FROM user_complete_profile ucp WHERE ucp.username = users.username
echo ^);
echo.
echo -- Create admin user profile if not exists
echo INSERT INTO user_profiles ^(user_id, profile_data^)
echo SELECT u.id, '{\"role\": \"admin\", \"permissions\": [\"all\"]}'::jsonb
echo FROM users u 
echo WHERE u.role = 'admin' AND NOT EXISTS ^(
echo     SELECT 1 FROM user_profiles up WHERE up.user_id = u.id
echo ^);
echo.
) > temp_complete_schema.sql

echo Applying complete schema...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -f temp_complete_schema.sql

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS! Complete database schema created.
    del temp_complete_schema.sql
    echo.
    echo Verifying installation...
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT COUNT(*) || ' total tables now in database' FROM information_schema.tables WHERE table_schema = 'public';"
    echo.
    echo Your CBA Portal database is now fully configured!
    echo All features will work properly.
) else (
    echo.
    echo ERROR: Failed to create complete schema!
    echo Check temp_complete_schema.sql for issues.
)

echo.
pause