-- ============================================
-- CBA PORTAL - CLEAN COMPLETE DATABASE SCHEMA
-- ============================================
-- This schema includes ALL tables needed by the application
-- with correct column names, data types, and relationships
-- No sample data - only one admin user

-- Set proper PostgreSQL settings
SET timezone = 'UTC';

-- Drop existing tables in correct order (foreign keys first)
DROP TABLE IF EXISTS ps_verifications CASCADE;
DROP TABLE IF EXISTS payslips CASCADE;
DROP TABLE IF EXISTS documents CASCADE;
DROP TABLE IF EXISTS attendance_records CASCADE;
DROP TABLE IF EXISTS leave_applications CASCADE;
DROP TABLE IF EXISTS staff_deductions CASCADE;
DROP TABLE IF EXISTS pension_nominees CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS user_activity CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS system_errors CASCADE;
DROP TABLE IF EXISTS admin_actions CASCADE;
DROP TABLE IF EXISTS admin_settings CASCADE;
DROP TABLE IF EXISTS admin_notifications CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS user_sessions CASCADE;
DROP TABLE IF EXISTS user_login_history CASCADE;
DROP TABLE IF EXISTS login_attempts CASCADE;
DROP TABLE IF EXISTS admissions CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS object_codes CASCADE;
DROP TABLE IF EXISTS function_codes CASCADE;
DROP TABLE IF EXISTS leave_types CASCADE;
DROP TABLE IF EXISTS designations CASCADE;
DROP TABLE IF EXISTS system_config CASCADE;

-- ============================================
-- CORE TABLES
-- ============================================

-- Users table (compatible with ALL route files)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),  -- Required by auth-enhanced.js
    email VARCHAR(255) UNIQUE,  -- Required by auth-enhanced.js
    phone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'user',
    status VARCHAR(20) DEFAULT 'active',
    rights JSON,  -- For admin.js permissions
    last_login TIMESTAMP,
    login_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User profiles (for admin.js extended info)
CREATE TABLE user_profiles (
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
);

-- Authentication tables (required by auth-enhanced.js)
CREATE TABLE login_attempts (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    success BOOLEAN DEFAULT FALSE,
    user_id INTEGER,
    failure_reason VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    session_token TEXT UNIQUE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE user_login_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_info JSON,
    login_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin action logging (required by admin.js)
CREATE TABLE admin_actions (
    id SERIAL PRIMARY KEY,
    admin_user_id INTEGER REFERENCES users(id),
    action_type VARCHAR(50),
    target_entity VARCHAR(50),
    target_id VARCHAR(50),
    action_details JSON,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- LOOKUP TABLES
-- ============================================

-- Designations
CREATE TABLE designations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    description TEXT,
    pay_level_min INTEGER,
    pay_level_max INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Function codes
CREATE TABLE function_codes (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Object codes  
CREATE TABLE object_codes (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Leave types
CREATE TABLE leave_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    max_days INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- STAFF MANAGEMENT TABLES
-- ============================================

-- Staff admissions/records
CREATE TABLE admissions (
    id SERIAL PRIMARY KEY,
    staff_id VARCHAR(20) UNIQUE,
    staff_name VARCHAR(255) NOT NULL,
    father_husband_name VARCHAR(255),
    designation VARCHAR(100),
    date_of_birth DATE,
    date_of_joining DATE,
    date_of_retirement DATE,
    mobile_number VARCHAR(15),
    email VARCHAR(255),
    address TEXT,
    qualification VARCHAR(255),
    experience_years INTEGER,
    aadhar_number VARCHAR(12),
    pan_number VARCHAR(10),
    bank_account VARCHAR(50),
    ifsc_code VARCHAR(11),
    basic_pay DECIMAL(10,2),
    grade_pay DECIMAL(10,2),
    da_percentage DECIMAL(5,2),
    hra_percentage DECIMAL(5,2),
    medical_allowance DECIMAL(10,2),
    transport_allowance DECIMAL(10,2),
    other_allowances DECIMAL(10,2),
    pf_number VARCHAR(50),
    esi_number VARCHAR(17),
    photo_path VARCHAR(500),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pension nominees
CREATE TABLE pension_nominees (
    id SERIAL PRIMARY KEY,
    staff_id VARCHAR(20) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    nominee_name VARCHAR(255) NOT NULL,
    relationship VARCHAR(50),
    percentage DECIMAL(5,2),
    date_of_birth DATE,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staff deductions
CREATE TABLE staff_deductions (
    id SERIAL PRIMARY KEY,
    staff_id VARCHAR(20) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    deduction_type VARCHAR(100),
    amount DECIMAL(10,2),
    start_date DATE,
    end_date DATE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- OPERATIONAL TABLES
-- ============================================

-- Leave applications
CREATE TABLE leave_applications (
    id SERIAL PRIMARY KEY,
    staff_id VARCHAR(20) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    leave_type_id INTEGER REFERENCES leave_types(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days_requested INTEGER,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    approved_by INTEGER REFERENCES users(id),
    approved_at TIMESTAMP,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Attendance records
CREATE TABLE attendance_records (
    id SERIAL PRIMARY KEY,
    staff_id VARCHAR(20) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    date DATE NOT NULL,
    time_in TIME,
    time_out TIME,
    status VARCHAR(20) DEFAULT 'present',
    overtime_hours DECIMAL(4,2),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(staff_id, date)
);

-- Documents
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    staff_id VARCHAR(20) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    document_type VARCHAR(100),
    document_name VARCHAR(255),
    file_path VARCHAR(500),
    file_size INTEGER,
    uploaded_by INTEGER REFERENCES users(id),
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by INTEGER REFERENCES users(id),
    verified_at TIMESTAMP
);

-- Payslips
CREATE TABLE payslips (
    id SERIAL PRIMARY KEY,
    staff_id VARCHAR(20) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    basic_pay DECIMAL(10,2),
    da DECIMAL(10,2),
    hra DECIMAL(10,2),
    medical_allowance DECIMAL(10,2),
    transport_allowance DECIMAL(10,2),
    other_allowances DECIMAL(10,2),
    gross_salary DECIMAL(10,2),
    pf_deduction DECIMAL(10,2),
    esi_deduction DECIMAL(10,2),
    tax_deduction DECIMAL(10,2),
    other_deductions DECIMAL(10,2),
    total_deductions DECIMAL(10,2),
    net_salary DECIMAL(10,2),
    generated_by INTEGER REFERENCES users(id),
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(staff_id, month, year)
);

-- PS Verifications
CREATE TABLE ps_verifications (
    id SERIAL PRIMARY KEY,
    staff_id VARCHAR(20) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    verification_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'pending',
    verified_by INTEGER REFERENCES users(id),
    verification_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- SYSTEM TABLES
-- ============================================

-- System configuration
CREATE TABLE system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin settings (for admin.js)
CREATE TABLE admin_settings (
    id SERIAL PRIMARY KEY,
    category VARCHAR(50),
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin notifications (for admin.js)
CREATE TABLE admin_notifications (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    message TEXT,
    type VARCHAR(50) DEFAULT 'info',
    priority INTEGER DEFAULT 1,
    is_read BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit log
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(100),
    table_name VARCHAR(100),
    record_id VARCHAR(50),
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User activity (for admin.js logs)
CREATE TABLE user_activity (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    activity_type VARCHAR(50),
    description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    title VARCHAR(255),
    message TEXT,
    type VARCHAR(50) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- System errors (for admin.js)
CREATE TABLE system_errors (
    id SERIAL PRIMARY KEY,
    error_type VARCHAR(100),
    error_message TEXT,
    stack_trace TEXT,
    user_id INTEGER REFERENCES users(id),
    ip_address VARCHAR(45),
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_by INTEGER REFERENCES users(id),
    resolved_at TIMESTAMP,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- VIEWS FOR ADMIN DASHBOARD
-- ============================================

-- Dashboard summary view (for admin.js)
CREATE VIEW admin_dashboard_summary AS
SELECT 
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM users WHERE status = 'active') as active_users,
    (SELECT COUNT(*) FROM users WHERE role IN ('admin', 'super_admin')) as admin_users,
    (SELECT COUNT(*) FROM admissions WHERE status = 'active') as total_staff,
    (SELECT COUNT(*) FROM leave_applications WHERE status = 'pending') as pending_leaves,
    (SELECT COUNT(*) FROM system_errors WHERE is_resolved = FALSE) as unresolved_errors,
    (SELECT COUNT(*) FROM admin_notifications WHERE is_read = FALSE) as unread_notifications,
    (SELECT COUNT(*) FROM user_sessions WHERE is_active = TRUE AND expires_at > CURRENT_TIMESTAMP) as active_sessions;

-- Recent activity view (for admin.js)
CREATE VIEW admin_recent_activity AS
SELECT 
    'user_login' as activity_type,
    u.username,
    u.full_name,
    'User logged in' as description,
    ulh.login_at as timestamp
FROM user_login_history ulh
JOIN users u ON ulh.user_id = u.id
UNION ALL
SELECT 
    aa.action_type,
    u.username,
    u.full_name,
    CONCAT(aa.action_type, ' on ', aa.target_entity) as description,
    aa.created_at
FROM admin_actions aa
JOIN users u ON aa.admin_user_id = u.id
ORDER BY timestamp DESC
LIMIT 50;

-- ============================================
-- INSERT SINGLE ADMIN USER
-- ============================================

-- Insert admin user (password: admin123)
INSERT INTO users (
    username, 
    password, 
    full_name, 
    email, 
    role, 
    status,
    created_at,
    updated_at
) VALUES (
    'admin',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy',
    'System Administrator',
    'admin@cba.gov.in',
    'admin',
    'active',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Insert admin profile
INSERT INTO user_profiles (
    user_id,
    department,
    designation,
    employee_id
) VALUES (
    1,
    'Administration',
    'System Administrator',
    'ADM001'
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- User indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);

-- Staff indexes
CREATE INDEX idx_admissions_staff_id ON admissions(staff_id);
CREATE INDEX idx_admissions_designation ON admissions(designation);
CREATE INDEX idx_admissions_status ON admissions(status);

-- Operational indexes
CREATE INDEX idx_payslips_staff_year_month ON payslips(staff_id, year, month);
CREATE INDEX idx_attendance_staff_date ON attendance_records(staff_id, date);
CREATE INDEX idx_leave_apps_staff ON leave_applications(staff_id);
CREATE INDEX idx_documents_staff ON documents(staff_id);

-- Audit indexes
CREATE INDEX idx_audit_user_action ON audit_log(user_id, action);
CREATE INDEX idx_user_activity_user_type ON user_activity(user_id, activity_type);

-- ============================================
-- PERMISSIONS
-- ============================================

-- Grant permissions to cba_admin user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cba_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cba_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO cba_admin;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check if everything was created correctly
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;
-- SELECT * FROM users WHERE username = 'admin';
-- SELECT COUNT(*) as total_tables FROM information_schema.tables WHERE table_schema = 'public';

COMMIT;