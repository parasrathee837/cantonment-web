-- PostgreSQL Enhanced Cantonment Board Administration System Database Schema v3.0
-- Updated: 2025-01-11
-- This schema includes ALL staff fields for complete admin and user portal functionality
-- Production-ready PostgreSQL version with proper constraints and indexes

-- ==================================================
-- Extensions and Setup
-- ==================================================

-- Enable UUID extension for better ID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable full-text search
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ==================================================
-- ENUMS
-- ==================================================

CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'operator', 'user');
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE admission_status AS ENUM ('pending', 'approved', 'rejected', 'inactive');
CREATE TYPE gender AS ENUM ('Male', 'Female', 'Other');
CREATE TYPE marital_status AS ENUM ('Single', 'Married', 'Divorced', 'Widowed');
CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'rejected');
CREATE TYPE notification_type AS ENUM ('info', 'warning', 'error', 'success');
CREATE TYPE audit_action AS ENUM ('INSERT', 'UPDATE', 'DELETE');

-- ==================================================
-- Main Staff/Admissions Table (COMPREHENSIVE)
-- ==================================================

DROP TABLE IF EXISTS admissions CASCADE;
CREATE TABLE admissions (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    
    -- Staff identification
    staff_id VARCHAR(50) UNIQUE NOT NULL,
    
    -- Basic Personal Information
    staff_name VARCHAR(100) NOT NULL,
    designation VARCHAR(100) NOT NULL,
    
    -- Personal Details
    date_of_birth DATE,
    age INTEGER CHECK (age >= 18 AND age <= 100),
    sex gender,
    nationality VARCHAR(50) DEFAULT 'Indian',
    
    -- Family Information
    father_name VARCHAR(100) NOT NULL,
    mother_name VARCHAR(100),
    grand_father_name VARCHAR(100),
    marital_status marital_status,
    spouse_name VARCHAR(100),
    children JSONB, -- JSON array of children objects
    
    -- Employment Information
    date_of_appointment DATE NOT NULL,
    retirement_date DATE,
    function_code VARCHAR(20) NOT NULL,
    object_code VARCHAR(20) NOT NULL,
    date_of_next_increment DATE,
    pension_scheme VARCHAR(50) NOT NULL,
    
    -- Contact Information & Documents
    mobile_number VARCHAR(10) NOT NULL CHECK (
        LENGTH(mobile_number) = 10 AND 
        mobile_number ~ '^[6-9][0-9]{9}$'
    ),
    aadhar_number VARCHAR(12) CHECK (
        aadhar_number IS NULL OR 
        (LENGTH(aadhar_number) = 12 AND aadhar_number ~ '^[0-9]{12}$')
    ),
    pan_number VARCHAR(10) CHECK (
        pan_number IS NULL OR
        pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]{1}$'
    ),
    permanent_address TEXT NOT NULL,
    communication_address TEXT NOT NULL,
    remarks TEXT,
    
    -- Bank Details
    bank_name VARCHAR(100),
    account_number VARCHAR(20),
    ifsc_code VARCHAR(11) CHECK (
        ifsc_code IS NULL OR 
        ifsc_code ~ '^[A-Z]{4}0[A-Z0-9]{6}$'
    ),
    micr_code VARCHAR(9) CHECK (
        micr_code IS NULL OR 
        micr_code ~ '^[0-9]{9}$'
    ),
    
    -- Salary Structure (7th Pay Commission)
    pay_band VARCHAR(50), -- e.g., "9300-34800", "5200-20200"
    grade_pay VARCHAR(20), -- e.g., "4800", "2400"
    pay_level INTEGER CHECK (pay_level >= 1 AND pay_level <= 18),
    pay_cell INTEGER CHECK (pay_cell >= 1),
    basic_pay_calculated DECIMAL(12,2) NOT NULL CHECK (basic_pay_calculated > 0),
    
    -- Allowances (DA/HRA as percentages, others as amounts)
    da DECIMAL(8,2) DEFAULT 50.0 CHECK (da >= 0),
    hra DECIMAL(8,2) DEFAULT 24.0 CHECK (hra >= 0),
    special_pay DECIMAL(10,2) DEFAULT 0 CHECK (special_pay >= 0),
    special_allowance DECIMAL(10,2) DEFAULT 0 CHECK (special_allowance >= 0),
    other_allowance DECIMAL(10,2) DEFAULT 0 CHECK (other_allowance >= 0),
    
    -- Calculated salary fields
    gross_salary DECIMAL(12,2) GENERATED ALWAYS AS (
        basic_pay_calculated + 
        (basic_pay_calculated * da / 100) +
        (basic_pay_calculated * hra / 100) +
        COALESCE(special_pay, 0) + 
        COALESCE(special_allowance, 0) + 
        COALESCE(other_allowance, 0)
    ) STORED,
    total_deductions DECIMAL(10,2) DEFAULT 0,
    net_salary DECIMAL(12,2) GENERATED ALWAYS AS (
        gross_salary - COALESCE(total_deductions, 0)
    ) STORED,
    
    -- Document and Photo storage
    photo TEXT, -- Base64 or file path
    documents JSONB, -- JSON array of document objects
    
    -- Legacy fields for backward compatibility
    email VARCHAR(100) CHECK (email IS NULL OR email ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$'),
    religion VARCHAR(50),
    category VARCHAR(50),
    present_address TEXT,
    employee_type VARCHAR(50),
    date_of_joining DATE,
    office_number VARCHAR(50),
    emergency_contact VARCHAR(15),
    basic_pay DECIMAL(12,2), -- Legacy field
    basic_salary DECIMAL(12,2), -- Legacy field
    
    -- System fields
    status admission_status DEFAULT 'approved',
    
    -- Full-text search
    search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('english', 
            COALESCE(staff_id, '') || ' ' ||
            COALESCE(staff_name, '') || ' ' ||
            COALESCE(father_name, '') || ' ' ||
            COALESCE(designation, '') || ' ' ||
            COALESCE(mobile_number, '')
        )
    ) STORED,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- Users Table (Enhanced for Admin Portal)
-- ==================================================

DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    
    -- Basic Information
    full_name VARCHAR(100) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE CHECK (email ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$'),
    
    -- Personal Details (for admin portal user management)
    date_of_birth DATE,
    age INTEGER CHECK (age >= 18 AND age <= 100),
    sex gender,
    nationality VARCHAR(50) DEFAULT 'Indian',
    
    -- Family Information (for admin portal)
    father_name VARCHAR(100),
    mother_name VARCHAR(100),
    grand_father_name VARCHAR(100),
    marital_status marital_status,
    spouse_name VARCHAR(100),
    children JSONB, -- JSON array of children objects
    
    -- Contact Information
    mobile_number VARCHAR(10) CHECK (
        mobile_number IS NULL OR 
        (LENGTH(mobile_number) = 10 AND mobile_number ~ '^[6-9][0-9]{9}$')
    ),
    permanent_address TEXT,
    communication_address TEXT,
    
    -- Documents
    aadhar_number VARCHAR(12) CHECK (
        aadhar_number IS NULL OR 
        (LENGTH(aadhar_number) = 12 AND aadhar_number ~ '^[0-9]{12}$')
    ),
    pan_number VARCHAR(10) CHECK (
        pan_number IS NULL OR
        pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]{1}$'
    ),
    
    -- System fields
    password_hash VARCHAR(255) NOT NULL,
    role user_role DEFAULT 'user',
    rights JSONB DEFAULT '["read"]'::jsonb, -- JSON array of permissions
    status user_status DEFAULT 'active',
    
    -- Login tracking
    last_login TIMESTAMPTZ,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMPTZ,
    
    -- Full-text search
    search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('english', 
            COALESCE(full_name, '') || ' ' ||
            COALESCE(username, '') || ' ' ||
            COALESCE(email, '')
        )
    ) STORED,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- Supporting Tables
-- ==================================================

-- Pension Nominees
DROP TABLE IF EXISTS pension_nominees CASCADE;
CREATE TABLE pension_nominees (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    staff_id VARCHAR(50) NOT NULL,
    nominee_name VARCHAR(100) NOT NULL,
    relation VARCHAR(50) NOT NULL CHECK (
        relation IN ('Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Other')
    ),
    percentage INTEGER NOT NULL CHECK (percentage >= 1 AND percentage <= 100),
    nominee_age INTEGER CHECK (nominee_age > 0 AND nominee_age <= 120),
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE
);

-- Staff Deductions
DROP TABLE IF EXISTS staff_deductions CASCADE;
CREATE TABLE staff_deductions (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    staff_id VARCHAR(50) NOT NULL,
    
    -- Standard deductions
    pf DECIMAL(10,2) DEFAULT 0 CHECK (pf >= 0),
    esi DECIMAL(10,2) DEFAULT 0 CHECK (esi >= 0),
    professional_tax DECIMAL(10,2) DEFAULT 0 CHECK (professional_tax >= 0),
    income_tax DECIMAL(10,2) DEFAULT 0 CHECK (income_tax >= 0),
    
    -- Loan deductions
    house_building_advance DECIMAL(10,2) DEFAULT 0 CHECK (house_building_advance >= 0),
    vehicle_advance DECIMAL(10,2) DEFAULT 0 CHECK (vehicle_advance >= 0),
    personal_loan DECIMAL(10,2) DEFAULT 0 CHECK (personal_loan >= 0),
    festival_advance DECIMAL(10,2) DEFAULT 0 CHECK (festival_advance >= 0),
    
    -- Other deductions
    other_deduction1_name VARCHAR(100),
    other_deduction1_amount DECIMAL(10,2) DEFAULT 0 CHECK (other_deduction1_amount >= 0),
    other_deduction2_name VARCHAR(100),
    other_deduction2_amount DECIMAL(10,2) DEFAULT 0 CHECK (other_deduction2_amount >= 0),
    
    -- Total calculated deduction
    total_deductions DECIMAL(10,2) GENERATED ALWAYS AS (
        COALESCE(pf, 0) + COALESCE(esi, 0) + COALESCE(professional_tax, 0) + 
        COALESCE(income_tax, 0) + COALESCE(house_building_advance, 0) + 
        COALESCE(vehicle_advance, 0) + COALESCE(personal_loan, 0) + 
        COALESCE(festival_advance, 0) + COALESCE(other_deduction1_amount, 0) + 
        COALESCE(other_deduction2_amount, 0)
    ) STORED,
    
    remarks TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE
);

-- Designations
DROP TABLE IF EXISTS designations CASCADE;
CREATE TABLE designations (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    name VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(100),
    pay_level_min INTEGER,
    pay_level_max INTEGER,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Function Codes
DROP TABLE IF EXISTS function_codes CASCADE;
CREATE TABLE function_codes (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Object Codes
DROP TABLE IF EXISTS object_codes CASCADE;
CREATE TABLE object_codes (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Leave Management Tables
DROP TABLE IF EXISTS leave_types CASCADE;
CREATE TABLE leave_types (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    name VARCHAR(50) UNIQUE NOT NULL,
    days_allowed INTEGER NOT NULL CHECK (days_allowed > 0),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS leave_applications CASCADE;
CREATE TABLE leave_applications (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    staff_id VARCHAR(50) NOT NULL,
    leave_type_id INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days INTEGER NOT NULL,
    reason TEXT NOT NULL,
    status leave_status DEFAULT 'pending',
    approved_by INTEGER,
    approved_at TIMESTAMPTZ,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (leave_type_id) REFERENCES leave_types(id),
    FOREIGN KEY (approved_by) REFERENCES users(id)
);

-- Attendance Records
DROP TABLE IF EXISTS attendance_records CASCADE;
CREATE TABLE attendance_records (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    staff_id VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    days_present INTEGER DEFAULT 0,
    days_absent INTEGER DEFAULT 0,
    overtime_hours DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    UNIQUE(staff_id, year, month)
);

-- Documents Management
DROP TABLE IF EXISTS documents CASCADE;
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    staff_id VARCHAR(50) NOT NULL,
    document_name VARCHAR(100) NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),
    verification_status verification_status DEFAULT 'pending',
    verified_by INTEGER,
    verified_at TIMESTAMPTZ,
    remarks TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id)
);

-- Payslips
DROP TABLE IF EXISTS payslips CASCADE;
CREATE TABLE payslips (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    staff_id VARCHAR(50) NOT NULL,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    year INTEGER NOT NULL,
    basic_salary DECIMAL(12,2) NOT NULL,
    da DECIMAL(10,2) DEFAULT 0,
    hra DECIMAL(10,2) DEFAULT 0,
    special_pay DECIMAL(10,2) DEFAULT 0,
    special_allowance DECIMAL(10,2) DEFAULT 0,
    other_allowance DECIMAL(10,2) DEFAULT 0,
    gross_salary DECIMAL(12,2) NOT NULL,
    total_deductions DECIMAL(10,2) DEFAULT 0,
    net_salary DECIMAL(12,2) NOT NULL,
    generated_by INTEGER,
    generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (generated_by) REFERENCES users(id),
    UNIQUE(staff_id, month, year)
);

-- PS Verifications
DROP TABLE IF EXISTS ps_verifications CASCADE;
CREATE TABLE ps_verifications (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    staff_id VARCHAR(50) NOT NULL,
    verification_type VARCHAR(50) NOT NULL,
    status verification_status DEFAULT 'pending',
    verified_by INTEGER,
    verified_at TIMESTAMPTZ,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id)
);

-- System Configuration
DROP TABLE IF EXISTS system_config CASCADE;
CREATE TABLE system_config (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    description TEXT,
    config_type VARCHAR(20) DEFAULT 'string' CHECK (config_type IN ('string', 'number', 'boolean', 'json')),
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Audit Log
DROP TABLE IF EXISTS audit_log CASCADE;
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id VARCHAR(50) NOT NULL,
    action audit_action NOT NULL,
    old_values JSONB,
    new_values JSONB,
    user_id INTEGER,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- User Activity
DROP TABLE IF EXISTS user_activity CASCADE;
CREATE TABLE user_activity (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    user_id INTEGER NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    activity_description TEXT NOT NULL,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Notifications
DROP TABLE IF EXISTS notifications CASCADE;
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    user_id INTEGER, -- NULL for system-wide notifications
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type notification_type DEFAULT 'info',
    priority INTEGER DEFAULT 1 CHECK (priority >= 1 AND priority <= 5),
    action_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_by INTEGER,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- System Errors
DROP TABLE IF EXISTS system_errors CASCADE;
CREATE TABLE system_errors (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    error_type VARCHAR(50) NOT NULL,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    user_id INTEGER,
    ip_address INET,
    url VARCHAR(500),
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ==================================================
-- Indexes for Performance
-- ==================================================

-- Primary search indexes
CREATE INDEX idx_admissions_staff_id ON admissions(staff_id);
CREATE INDEX idx_admissions_mobile ON admissions(mobile_number);
CREATE INDEX idx_admissions_name ON admissions USING gin(staff_name gin_trgm_ops);
CREATE INDEX idx_admissions_designation ON admissions(designation);
CREATE INDEX idx_admissions_status ON admissions(status);
CREATE INDEX idx_admissions_appointment_date ON admissions(date_of_appointment);
CREATE INDEX idx_admissions_search ON admissions USING gin(search_vector);

-- User indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_search ON users USING gin(search_vector);

-- Foreign key indexes
CREATE INDEX idx_nominees_staff_id ON pension_nominees(staff_id);
CREATE INDEX idx_deductions_staff_id ON staff_deductions(staff_id);
CREATE INDEX idx_leave_applications_staff_id ON leave_applications(staff_id);
CREATE INDEX idx_attendance_staff_id ON attendance_records(staff_id);
CREATE INDEX idx_documents_staff_id ON documents(staff_id);
CREATE INDEX idx_payslips_staff_id ON payslips(staff_id);
CREATE INDEX idx_ps_verifications_staff_id ON ps_verifications(staff_id);

-- Time-based indexes
CREATE INDEX idx_leave_applications_dates ON leave_applications(start_date, end_date);
CREATE INDEX idx_attendance_year_month ON attendance_records(year, month);
CREATE INDEX idx_payslips_year_month ON payslips(year, month);

-- Audit indexes
CREATE INDEX idx_audit_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_created ON audit_log(created_at);
CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_user_activity_user ON user_activity(user_id);
CREATE INDEX idx_user_activity_timestamp ON user_activity(timestamp);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- JSON indexes
CREATE INDEX idx_admissions_children ON admissions USING gin(children);
CREATE INDEX idx_users_children ON users USING gin(children);
CREATE INDEX idx_users_rights ON users USING gin(rights);

-- ==================================================
-- Functions and Triggers
-- ==================================================

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply timestamp trigger to relevant tables
CREATE TRIGGER update_admissions_updated_at BEFORE UPDATE ON admissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_staff_deductions_updated_at BEFORE UPDATE ON staff_deductions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON attendance_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update total deductions in admissions table
CREATE OR REPLACE FUNCTION update_admission_total_deductions()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE admissions 
    SET total_deductions = NEW.total_deductions
    WHERE staff_id = NEW.staff_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_admission_deductions_trigger
    AFTER INSERT OR UPDATE ON staff_deductions
    FOR EACH ROW EXECUTE FUNCTION update_admission_total_deductions();

-- ==================================================
-- Views
-- ==================================================

-- Active staff with complete information
CREATE VIEW active_staff_view AS
SELECT 
    a.*,
    d.name as designation_name,
    d.department,
    COALESCE(sd.total_deductions, 0) as current_deductions
FROM admissions a
LEFT JOIN designations d ON a.designation = d.name
LEFT JOIN staff_deductions sd ON a.staff_id = sd.staff_id AND sd.is_active = TRUE
WHERE a.status = 'approved';

-- Staff payroll information
CREATE VIEW staff_payroll_view AS
SELECT 
    a.staff_id,
    a.staff_name,
    a.designation,
    a.basic_pay_calculated,
    a.da,
    a.hra,
    a.special_pay,
    a.special_allowance,
    a.other_allowance,
    a.gross_salary,
    COALESCE(sd.total_deductions, 0) as total_deductions,
    a.net_salary,
    a.bank_name,
    a.account_number,
    a.ifsc_code
FROM admissions a
LEFT JOIN staff_deductions sd ON a.staff_id = sd.staff_id AND sd.is_active = TRUE
WHERE a.status = 'approved';

-- User management view
CREATE VIEW user_management_view AS
SELECT 
    u.id,
    u.uuid,
    u.full_name,
    u.username,
    u.email,
    u.role,
    u.rights,
    u.status,
    u.mobile_number,
    u.date_of_birth,
    u.age,
    u.sex,
    u.nationality,
    u.father_name,
    u.mother_name,
    u.grand_father_name,
    u.marital_status,
    u.spouse_name,
    u.children,
    u.permanent_address,
    u.communication_address,
    u.aadhar_number,
    u.pan_number,
    u.last_login,
    u.created_at
FROM users u
WHERE u.status != 'suspended';

-- ==================================================
-- Initial Data
-- ==================================================

-- Insert default system configurations
INSERT INTO system_config (config_key, config_value, description, config_type) VALUES
('organization_name', 'Cantonment Board Administration', 'Organization name for reports and headers', 'string'),
('mobile_number_validation', 'true', 'Enable strict mobile number validation', 'boolean'),
('max_login_attempts', '5', 'Maximum failed login attempts before account lock', 'number'),
('session_timeout_minutes', '120', 'Session timeout in minutes', 'number'),
('enable_audit_log', 'true', 'Enable audit logging for all operations', 'boolean'),
('da_percentage', '50.0', 'Current DA percentage for salary calculations', 'number'),
('hra_percentage', '24.0', 'Current HRA percentage for salary calculations', 'number'),
('organization_address', 'Cantonment Board, Ambala', 'Organization address for official documents', 'string'),
('financial_year_start', '04', 'Financial year start month (1-12)', 'number');

-- Insert default designations
INSERT INTO designations (name, department, pay_level_min, pay_level_max, description) VALUES
('Executive Engineer', 'Engineering', 10, 12, 'Senior engineering position'),
('Assistant Engineer', 'Engineering', 7, 9, 'Junior engineering position'),
('Junior Engineer', 'Engineering', 5, 7, 'Entry level engineering position'),
('Administrative Officer', 'Administration', 8, 10, 'Administrative management position'),
('Assistant Administrative Officer', 'Administration', 6, 8, 'Assistant administrative position'),
('Assistant', 'Administration', 3, 5, 'General administrative support'),
('Senior Clerk', 'Administration', 3, 5, 'Senior clerical position'),
('Clerk', 'Administration', 2, 4, 'Clerical and data entry work'),
('Accountant', 'Finance', 4, 6, 'Financial accounting and bookkeeping'),
('Senior Accountant', 'Finance', 6, 8, 'Senior financial position');

-- Insert function and object codes
INSERT INTO function_codes (code, name, description, category) VALUES
('2235', 'Other Administrative Services', 'General administrative functions', 'Administration'),
('4059', 'Capital Outlay on Public Works', 'Infrastructure development and maintenance', 'Public Works'),
('2059', 'Public Works', 'Regular public works maintenance', 'Public Works'),
('2217', 'Urban Development', 'Urban planning and development', 'Development');

INSERT INTO object_codes (code, name, description, category) VALUES
('01', 'Salaries', 'Staff salaries and wages', 'Personnel'),
('02', 'Wages', 'Daily wage payments', 'Personnel'),
('13', 'Office Expenses', 'General office operational expenses', 'Office'),
('17', 'Maintenance', 'Equipment and facility maintenance', 'Maintenance');

-- Insert leave types
INSERT INTO leave_types (name, days_allowed, description) VALUES
('Earned Leave', 30, 'Annual earned leave entitlement'),
('Casual Leave', 12, 'Casual leave for personal work'),
('Medical Leave', 90, 'Medical leave for health issues'),
('Maternity Leave', 180, 'Maternity leave for female employees');

-- Insert default admin users
INSERT INTO users (full_name, username, email, password_hash, role, status) VALUES
('System Administrator', 'admin', 'admin@cantonmentboard.gov.in', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKzHof2wKzm1Zd.', 'super_admin', 'active'),
('Super Administrator', 'superadmin', 'superadmin@cantonmentboard.gov.in', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKzHof2wKzm1Zd.', 'super_admin', 'active');

-- ==================================================
-- Permissions and Security
-- ==================================================

-- Create role for application users
CREATE ROLE cantonment_app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO cantonment_app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO cantonment_app_user;

-- Create role for read-only access
CREATE ROLE cantonment_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cantonment_readonly;

-- ==================================================
-- Verification
-- ==================================================

-- Check schema creation
SELECT 'PostgreSQL Enhanced Schema v3.0 created successfully. Tables: ' || COUNT(*) as status 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';