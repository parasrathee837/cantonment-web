-- Enhanced Cantonment Board Administration System Database Schema v3.0
-- Updated: 2025-01-11
-- This schema includes ALL staff fields for complete admin and user portal functionality
-- Includes all fields from the "Add New Staff" form for both admin and user portals

-- ==================================================
-- Main Staff/Admissions Table (COMPREHENSIVE)
-- ==================================================

DROP TABLE IF EXISTS admissions;
CREATE TABLE admissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- Staff identification
    staff_id VARCHAR(50) UNIQUE NOT NULL,
    
    -- Basic Personal Information
    staff_name VARCHAR(100) NOT NULL,
    designation VARCHAR(100) NOT NULL,
    
    -- Personal Details
    date_of_birth DATE,
    age INTEGER CHECK (age >= 18 AND age <= 100),
    sex VARCHAR(10) CHECK (sex IN ('Male', 'Female', 'Other')),
    nationality VARCHAR(50) DEFAULT 'Indian',
    
    -- Family Information
    father_name VARCHAR(100) NOT NULL,
    mother_name VARCHAR(100),
    grand_father_name VARCHAR(100),
    marital_status VARCHAR(20) CHECK (marital_status IN ('Single', 'Married', 'Divorced', 'Widowed')),
    spouse_name VARCHAR(100),
    children TEXT, -- JSON array of children objects with name, gender, age
    
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
        mobile_number GLOB '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' AND
        SUBSTR(mobile_number, 1, 1) IN ('6', '7', '8', '9')
    ),
    aadhar_number VARCHAR(12) CHECK (
        aadhar_number IS NULL OR 
        (LENGTH(aadhar_number) = 12 AND aadhar_number GLOB '[0-9]*')
    ),
    pan_number VARCHAR(10) CHECK (
        pan_number IS NULL OR
        (LENGTH(pan_number) = 10 AND pan_number GLOB '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]')
    ),
    permanent_address TEXT NOT NULL,
    communication_address TEXT NOT NULL,
    remarks TEXT,
    
    -- Bank Details
    bank_name VARCHAR(100),
    account_number VARCHAR(20),
    ifsc_code VARCHAR(11) CHECK (
        ifsc_code IS NULL OR 
        (LENGTH(ifsc_code) = 11 AND ifsc_code GLOB '[A-Z][A-Z][A-Z][A-Z]0[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]')
    ),
    micr_code VARCHAR(9) CHECK (
        micr_code IS NULL OR 
        (LENGTH(micr_code) = 9 AND micr_code GLOB '[0-9]*')
    ),
    
    -- Salary Structure (7th Pay Commission)
    pay_band VARCHAR(50), -- e.g., "9300-34800", "5200-20200"
    grade_pay VARCHAR(20), -- e.g., "4800", "2400"
    pay_level INTEGER CHECK (pay_level >= 1 AND pay_level <= 18), -- New 7th Pay Commission Level
    pay_cell INTEGER CHECK (pay_cell >= 1), -- Pay cell within level
    basic_pay_calculated DECIMAL(12,2) NOT NULL CHECK (basic_pay_calculated > 0), -- Calculated basic pay
    
    -- Allowances (stored as percentages for DA/HRA, amounts for others)
    da DECIMAL(8,2) DEFAULT 50.0 CHECK (da >= 0), -- Dearness Allowance (percentage)
    hra DECIMAL(8,2) DEFAULT 24.0 CHECK (hra >= 0), -- House Rent Allowance (percentage)
    special_pay DECIMAL(10,2) DEFAULT 0 CHECK (special_pay >= 0), -- Fixed amount
    special_allowance DECIMAL(10,2) DEFAULT 0 CHECK (special_allowance >= 0), -- Fixed amount
    other_allowance DECIMAL(10,2) DEFAULT 0 CHECK (other_allowance >= 0), -- Fixed amount
    
    -- Calculated salary fields (auto-calculated)
    gross_salary DECIMAL(12,2), -- Total gross salary
    total_deductions DECIMAL(10,2) DEFAULT 0,
    net_salary DECIMAL(12,2),
    
    -- Document and Photo storage
    photo TEXT, -- Base64 encoded image or file path
    documents TEXT, -- JSON array of document objects
    
    -- Legacy fields for backward compatibility
    email VARCHAR(100) CHECK (email IS NULL OR email LIKE '%@%.%'),
    religion VARCHAR(50),
    category VARCHAR(50),
    present_address TEXT,
    employee_type VARCHAR(50),
    date_of_joining DATE,
    office_number VARCHAR(50),
    emergency_contact VARCHAR(15),
    basic_pay DECIMAL(12,2), -- Legacy field for old pay structure
    basic_salary DECIMAL(12,2), -- Legacy field for payslip calculations
    
    -- System fields
    status VARCHAR(20) DEFAULT 'approved' CHECK (status IN ('pending', 'approved', 'rejected', 'inactive')),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- Users Table (Enhanced for Admin Portal)
-- ==================================================

DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- Basic Information
    full_name VARCHAR(100) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    
    -- Personal Details (for admin portal user management)
    date_of_birth DATE,
    age INTEGER CHECK (age >= 18 AND age <= 100),
    sex VARCHAR(10) CHECK (sex IN ('Male', 'Female', 'Other')),
    nationality VARCHAR(50) DEFAULT 'Indian',
    
    -- Family Information (for admin portal)
    father_name VARCHAR(100),
    mother_name VARCHAR(100),
    grand_father_name VARCHAR(100),
    marital_status VARCHAR(20) CHECK (marital_status IN ('Single', 'Married', 'Divorced', 'Widowed')),
    spouse_name VARCHAR(100),
    children TEXT, -- JSON array of children objects
    
    -- Contact Information
    mobile_number VARCHAR(10) CHECK (
        mobile_number IS NULL OR (
            LENGTH(mobile_number) = 10 AND 
            mobile_number GLOB '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' AND
            SUBSTR(mobile_number, 1, 1) IN ('6', '7', '8', '9')
        )
    ),
    permanent_address TEXT,
    communication_address TEXT,
    
    -- Documents
    aadhar_number VARCHAR(12) CHECK (
        aadhar_number IS NULL OR 
        (LENGTH(aadhar_number) = 12 AND aadhar_number GLOB '[0-9]*')
    ),
    pan_number VARCHAR(10) CHECK (
        pan_number IS NULL OR
        (LENGTH(pan_number) = 10 AND pan_number GLOB '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]')
    ),
    
    -- System fields
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('super_admin', 'admin', 'operator', 'user')),
    rights TEXT, -- JSON array of permissions/rights
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    
    -- Login tracking
    last_login TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- Pension Nominees Table
-- ==================================================

DROP TABLE IF EXISTS pension_nominees;
CREATE TABLE pension_nominees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    nominee_name VARCHAR(100) NOT NULL,
    relation VARCHAR(50) NOT NULL CHECK (
        relation IN ('Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Other')
    ),
    percentage INTEGER NOT NULL CHECK (percentage >= 1 AND percentage <= 100),
    nominee_age INTEGER CHECK (nominee_age > 0 AND nominee_age <= 120),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE
);

-- ==================================================
-- Staff Deductions Table
-- ==================================================

DROP TABLE IF EXISTS staff_deductions;
CREATE TABLE staff_deductions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    
    -- Standard deductions
    pf DECIMAL(10,2) DEFAULT 0 CHECK (pf >= 0), -- Provident Fund
    esi DECIMAL(10,2) DEFAULT 0 CHECK (esi >= 0), -- Employee State Insurance
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
    total_deductions DECIMAL(10,2) DEFAULT 0,
    
    remarks TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE
);

-- ==================================================
-- Designations Table
-- ==================================================

DROP TABLE IF EXISTS designations;
CREATE TABLE designations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(100),
    pay_level_min INTEGER,
    pay_level_max INTEGER,
    description TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- Function Codes Table
-- ==================================================

DROP TABLE IF EXISTS function_codes;
CREATE TABLE function_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- Object Codes Table
-- ==================================================

DROP TABLE IF EXISTS object_codes;
CREATE TABLE object_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- Leave Management Tables
-- ==================================================

DROP TABLE IF EXISTS leave_types;
CREATE TABLE leave_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    days_allowed INTEGER NOT NULL CHECK (days_allowed > 0),
    description TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS leave_applications;
CREATE TABLE leave_applications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    leave_type_id INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days INTEGER NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    approved_by INTEGER,
    approved_at TIMESTAMP,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (leave_type_id) REFERENCES leave_types(id),
    FOREIGN KEY (approved_by) REFERENCES users(id)
);

-- ==================================================
-- Attendance Tables
-- ==================================================

DROP TABLE IF EXISTS attendance_records;
CREATE TABLE attendance_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    days_present INTEGER DEFAULT 0,
    days_absent INTEGER DEFAULT 0,
    overtime_hours DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    UNIQUE(staff_id, year, month)
);

-- ==================================================
-- Document Management Tables
-- ==================================================

DROP TABLE IF EXISTS documents;
CREATE TABLE documents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    document_name VARCHAR(100) NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    verified_by INTEGER,
    verified_at TIMESTAMP,
    remarks TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id)
);

-- ==================================================
-- Payslip Tables
-- ==================================================

DROP TABLE IF EXISTS payslips;
CREATE TABLE payslips (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (generated_by) REFERENCES users(id),
    UNIQUE(staff_id, month, year)
);

-- ==================================================
-- PS Verification Table
-- ==================================================

DROP TABLE IF EXISTS ps_verifications;
CREATE TABLE ps_verifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    verification_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
    verified_by INTEGER,
    verified_at TIMESTAMP,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id)
);

-- ==================================================
-- System Configuration Table
-- ==================================================

DROP TABLE IF EXISTS system_config;
CREATE TABLE system_config (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    description TEXT,
    config_type VARCHAR(20) DEFAULT 'string' CHECK (config_type IN ('string', 'number', 'boolean', 'json')),
    is_public BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- Audit Log Table
-- ==================================================

DROP TABLE IF EXISTS audit_log;
CREATE TABLE audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name VARCHAR(50) NOT NULL,
    record_id VARCHAR(50) NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values TEXT, -- JSON
    new_values TEXT, -- JSON
    user_id INTEGER,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ==================================================
-- User Activity Table
-- ==================================================

DROP TABLE IF EXISTS user_activity;
CREATE TABLE user_activity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    activity_description TEXT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ==================================================
-- Notifications Table
-- ==================================================

DROP TABLE IF EXISTS notifications;
CREATE TABLE notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER, -- NULL for system-wide notifications
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'info' CHECK (type IN ('info', 'warning', 'error', 'success')),
    priority INTEGER DEFAULT 1 CHECK (priority >= 1 AND priority <= 5),
    action_url TEXT,
    is_read BOOLEAN DEFAULT 0,
    read_at TIMESTAMP,
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- ==================================================
-- System Errors Table
-- ==================================================

DROP TABLE IF EXISTS system_errors;
CREATE TABLE system_errors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    error_type VARCHAR(50) NOT NULL,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    user_id INTEGER,
    ip_address VARCHAR(45),
    url VARCHAR(500),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ==================================================
-- Indexes for Performance
-- ==================================================

-- Primary search indexes
CREATE INDEX idx_admissions_staff_id ON admissions(staff_id);
CREATE INDEX idx_admissions_mobile ON admissions(mobile_number);
CREATE INDEX idx_admissions_name ON admissions(staff_name);
CREATE INDEX idx_admissions_designation ON admissions(designation);
CREATE INDEX idx_admissions_status ON admissions(status);
CREATE INDEX idx_admissions_appointment_date ON admissions(date_of_appointment);

-- User indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_role ON users(role);

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

-- ==================================================
-- Database Triggers
-- ==================================================

-- Trigger to update timestamps
CREATE TRIGGER update_admissions_timestamp 
    AFTER UPDATE ON admissions
    FOR EACH ROW
    BEGIN
        UPDATE admissions SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;

CREATE TRIGGER update_users_timestamp 
    AFTER UPDATE ON users
    FOR EACH ROW
    BEGIN
        UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;

-- Trigger to validate mobile number format for admissions
CREATE TRIGGER validate_admissions_mobile_number_trigger
    BEFORE INSERT ON admissions
    FOR EACH ROW
    WHEN NEW.mobile_number IS NOT NULL
    BEGIN
        SELECT CASE
            WHEN LENGTH(NEW.mobile_number) != 10 THEN
                RAISE(ABORT, 'Mobile number must be exactly 10 digits')
            WHEN NEW.mobile_number NOT GLOB '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' THEN
                RAISE(ABORT, 'Mobile number must contain only digits')
            WHEN SUBSTR(NEW.mobile_number, 1, 1) NOT IN ('6', '7', '8', '9') THEN
                RAISE(ABORT, 'Mobile number must start with 6, 7, 8, or 9')
        END;
    END;

-- Trigger to validate mobile number format for users
CREATE TRIGGER validate_users_mobile_number_trigger
    BEFORE INSERT ON users
    FOR EACH ROW
    WHEN NEW.mobile_number IS NOT NULL
    BEGIN
        SELECT CASE
            WHEN LENGTH(NEW.mobile_number) != 10 THEN
                RAISE(ABORT, 'Mobile number must be exactly 10 digits')
            WHEN NEW.mobile_number NOT GLOB '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' THEN
                RAISE(ABORT, 'Mobile number must contain only digits')
            WHEN SUBSTR(NEW.mobile_number, 1, 1) NOT IN ('6', '7', '8', '9') THEN
                RAISE(ABORT, 'Mobile number must start with 6, 7, 8, or 9')
        END;
    END;

-- Trigger to calculate total deductions
CREATE TRIGGER calculate_total_deductions
    AFTER INSERT OR UPDATE ON staff_deductions
    FOR EACH ROW
    BEGIN
        UPDATE staff_deductions 
        SET total_deductions = (
            COALESCE(pf, 0) + COALESCE(esi, 0) + COALESCE(professional_tax, 0) + 
            COALESCE(income_tax, 0) + COALESCE(house_building_advance, 0) + 
            COALESCE(vehicle_advance, 0) + COALESCE(personal_loan, 0) + 
            COALESCE(festival_advance, 0) + COALESCE(other_deduction1_amount, 0) + 
            COALESCE(other_deduction2_amount, 0)
        )
        WHERE id = NEW.id;
    END;

-- Trigger to calculate gross salary
CREATE TRIGGER calculate_gross_salary
    AFTER INSERT OR UPDATE ON admissions
    FOR EACH ROW
    WHEN NEW.basic_pay_calculated IS NOT NULL
    BEGIN
        UPDATE admissions 
        SET gross_salary = (
            COALESCE(basic_pay_calculated, 0) + 
            COALESCE((basic_pay_calculated * da / 100), 0) +
            COALESCE((basic_pay_calculated * hra / 100), 0) +
            COALESCE(special_pay, 0) + 
            COALESCE(special_allowance, 0) + 
            COALESCE(other_allowance, 0)
        )
        WHERE id = NEW.id;
    END;

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
('Senior Accountant', 'Finance', 6, 8, 'Senior financial position'),
('Sweeper', 'Sanitation', 1, 2, 'Sanitation and cleaning work'),
('Mali', 'Horticulture', 1, 3, 'Gardening and landscaping work'),
('Security Guard', 'Security', 1, 3, 'Security and surveillance work'),
('Driver', 'Transport', 2, 4, 'Vehicle driving and maintenance');

-- Insert default function codes
INSERT INTO function_codes (code, name, description, category) VALUES
('2235', 'Other Administrative Services', 'General administrative functions', 'Administration'),
('4059', 'Capital Outlay on Public Works', 'Infrastructure development and maintenance', 'Public Works'),
('2059', 'Public Works', 'Regular public works maintenance', 'Public Works'),
('2217', 'Urban Development', 'Urban planning and development', 'Development'),
('3604', 'Compensation and Assignments', 'Staff compensation and related expenses', 'Human Resources'),
('4216', 'Capital Outlay on Housing', 'Housing development projects', 'Housing'),
('2216', 'Housing', 'Housing maintenance and services', 'Housing'),
('2851', 'Village and Small Industries', 'Support for local industries', 'Economic Development');

-- Insert default object codes
INSERT INTO object_codes (code, name, description, category) VALUES
('01', 'Salaries', 'Staff salaries and wages', 'Personnel'),
('02', 'Wages', 'Daily wage payments', 'Personnel'),
('03', 'Overtime Allowance', 'Overtime compensation', 'Personnel'),
('04', 'Ad-hoc Bonus', 'Performance and festival bonuses', 'Personnel'),
('06', 'Medical Treatment', 'Medical expenses and treatments', 'Medical'),
('11', 'Domestic Travel Expenses', 'Local travel and transportation', 'Travel'),
('12', 'Foreign Travel Expenses', 'International travel expenses', 'Travel'),
('13', 'Office Expenses', 'General office operational expenses', 'Office'),
('14', 'Rents, Rates and Taxes', 'Property rent and tax payments', 'Property'),
('16', 'Professional Services', 'Consultant and professional fees', 'Services'),
('17', 'Maintenance', 'Equipment and facility maintenance', 'Maintenance'),
('21', 'Supplies and Materials', 'Office supplies and materials', 'Supplies'),
('22', 'Arms and Ammunition', 'Security equipment and supplies', 'Security'),
('24', 'P.O.L', 'Petrol, Oil, and Lubricants', 'Fuel'),
('25', 'Minor Works', 'Small construction and repair works', 'Construction'),
('27', 'Minor Equipment', 'Small equipment purchases', 'Equipment'),
('28', 'Major Equipment', 'Large equipment and machinery', 'Equipment'),
('31', 'Grants-in-aid-General', 'General financial assistance', 'Grants'),
('35', 'Grants for creation of capital assets', 'Capital development grants', 'Capital'),
('42', 'Other Expenses', 'Miscellaneous operational expenses', 'Miscellaneous');

-- Insert default leave types
INSERT INTO leave_types (name, days_allowed, description) VALUES
('Earned Leave', 30, 'Annual earned leave entitlement'),
('Casual Leave', 12, 'Casual leave for personal work'),
('Medical Leave', 90, 'Medical leave for health issues'),
('Maternity Leave', 180, 'Maternity leave for female employees'),
('Paternity Leave', 15, 'Paternity leave for male employees'),
('Study Leave', 365, 'Educational and training leave');

-- Insert default admin user (password should be changed after first login)
-- Password: admin123 (hashed)
INSERT INTO users (full_name, username, email, password_hash, role, status) VALUES
('System Administrator', 'admin', 'admin@cantonmentboard.gov.in', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKzHof2wKzm1Zd.', 'super_admin', 'active'),
('Super Administrator', 'superadmin', 'superadmin@cantonmentboard.gov.in', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKzHof2wKzm1Zd.', 'super_admin', 'active');

-- ==================================================
-- Views for Common Queries
-- ==================================================

-- View for active staff with complete information
CREATE VIEW active_staff_view AS
SELECT 
    a.*,
    d.name as designation_name,
    d.department,
    COALESCE(sd.total_deductions, 0) as current_deductions,
    (a.gross_salary - COALESCE(sd.total_deductions, 0)) as net_calculated_salary
FROM admissions a
LEFT JOIN designations d ON a.designation = d.name
LEFT JOIN staff_deductions sd ON a.staff_id = sd.staff_id AND sd.is_active = 1
WHERE a.status = 'approved';

-- View for staff with payroll information
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
    (a.gross_salary - COALESCE(sd.total_deductions, 0)) as net_salary,
    a.bank_name,
    a.account_number,
    a.ifsc_code
FROM admissions a
LEFT JOIN staff_deductions sd ON a.staff_id = sd.staff_id AND sd.is_active = 1
WHERE a.status = 'approved';

-- View for user management (admin portal)
CREATE VIEW user_management_view AS
SELECT 
    u.id,
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
WHERE u.status != 'deleted';

-- ==================================================
-- End of Schema
-- ==================================================

-- Run this query to verify the schema was created successfully:
SELECT 'Enhanced Schema v3.0 created successfully. Tables: ' || COUNT(*) as status 
FROM sqlite_master 
WHERE type = 'table' AND name NOT LIKE 'sqlite_%';