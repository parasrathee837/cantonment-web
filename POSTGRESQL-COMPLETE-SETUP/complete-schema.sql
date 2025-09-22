-- CBA Portal Complete Schema for PostgreSQL
-- This creates all necessary tables for the application

-- Drop existing types to avoid conflicts
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS user_status CASCADE;
DROP TYPE IF EXISTS admission_status CASCADE;
DROP TYPE IF EXISTS gender CASCADE;
DROP TYPE IF EXISTS marital_status CASCADE;
DROP TYPE IF EXISTS leave_status CASCADE;
DROP TYPE IF EXISTS verification_status CASCADE;

-- Create ENUM types
CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'operator', 'user');
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE admission_status AS ENUM ('pending', 'approved', 'rejected', 'inactive');
CREATE TYPE gender AS ENUM ('Male', 'Female', 'Other');
CREATE TYPE marital_status AS ENUM ('Single', 'Married', 'Divorced', 'Widowed');
CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'rejected');

-- Extended users table with all fields
CREATE TABLE IF NOT EXISTS user_complete_profile (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    email VARCHAR(100),
    mobile VARCHAR(15),
    role VARCHAR(20) DEFAULT 'user',
    status user_status DEFAULT 'active',
    
    -- Personal Information
    date_of_birth DATE,
    gender gender,
    marital_status marital_status,
    nationality VARCHAR(50) DEFAULT 'Indian',
    
    -- Employment Information
    employee_id VARCHAR(50) UNIQUE,
    designation VARCHAR(100),
    department VARCHAR(100),
    date_of_joining DATE,
    
    -- Contact Information
    permanent_address TEXT,
    communication_address TEXT,
    emergency_contact VARCHAR(15),
    emergency_contact_name VARCHAR(100),
    
    -- Documents
    aadhar_number VARCHAR(12),
    pan_number VARCHAR(10),
    
    -- Bank Details
    bank_name VARCHAR(100),
    account_number VARCHAR(20),
    ifsc_code VARCHAR(11),
    
    -- Other
    profile_photo VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Attendance table
CREATE TABLE IF NOT EXISTS attendance (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    date DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('present', 'absent', 'leave', 'holiday', 'half_day')),
    check_in_time TIME,
    check_out_time TIME,
    overtime_hours DECIMAL(4,2),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Leave management
CREATE TABLE IF NOT EXISTS leaves (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    leave_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status leave_status DEFAULT 'pending',
    approved_by INTEGER,
    approved_at TIMESTAMP,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payslips
CREATE TABLE IF NOT EXISTS payslips (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    year INTEGER NOT NULL,
    
    -- Earnings
    basic_salary DECIMAL(10,2),
    da DECIMAL(10,2), -- Dearness Allowance
    hra DECIMAL(10,2), -- House Rent Allowance
    ta DECIMAL(10,2), -- Travel Allowance
    medical_allowance DECIMAL(10,2),
    special_allowance DECIMAL(10,2),
    other_allowances DECIMAL(10,2),
    gross_salary DECIMAL(10,2),
    
    -- Deductions
    pf DECIMAL(10,2), -- Provident Fund
    professional_tax DECIMAL(10,2),
    income_tax DECIMAL(10,2),
    other_deductions DECIMAL(10,2),
    total_deductions DECIMAL(10,2),
    
    -- Net
    net_salary DECIMAL(10,2),
    
    -- Status
    payment_date DATE,
    payment_mode VARCHAR(50),
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    generated_by INTEGER
);

-- Function and Object Codes
CREATE TABLE IF NOT EXISTS codes (
    id SERIAL PRIMARY KEY,
    code_type VARCHAR(50) NOT NULL CHECK (code_type IN ('function', 'object')),
    code VARCHAR(20) NOT NULL,
    description VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(code_type, code)
);

-- File uploads
CREATE TABLE IF NOT EXISTS files (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(50),
    file_size INTEGER,
    category VARCHAR(50),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uploaded_by INTEGER
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'info',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50),
    entity_id INTEGER,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Settings
CREATE TABLE IF NOT EXISTS settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(50),
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_attendance_user_date ON attendance(user_id, date);
CREATE INDEX IF NOT EXISTS idx_leaves_user_status ON leaves(user_id, status);
CREATE INDEX IF NOT EXISTS idx_payslips_user_month_year ON payslips(user_id, month, year);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_created ON audit_logs(user_id, created_at);

-- Insert default codes
INSERT INTO codes (code_type, code, description) VALUES 
('function', 'ADM', 'Administration'),
('function', 'FIN', 'Finance'),
('function', 'HR', 'Human Resources'),
('function', 'IT', 'Information Technology'),
('function', 'SEC', 'Security'),
('object', 'SAL', 'Salary'),
('object', 'BEN', 'Benefits'),
('object', 'TRV', 'Travel'),
('object', 'OFF', 'Office Expenses'),
('object', 'MAI', 'Maintenance')
ON CONFLICT DO NOTHING;

-- Copy existing users data to user_complete_profile if not exists
INSERT INTO user_complete_profile (username, password, role, created_at, updated_at)
SELECT username, password, role, created_at, updated_at 
FROM users 
WHERE NOT EXISTS (
    SELECT 1 FROM user_complete_profile ucp WHERE ucp.username = users.username
);

-- Grant permissions (adjust as needed)
GRANT ALL ON ALL TABLES IN SCHEMA public TO cba_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO cba_admin;

-- Add triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_complete_profile_updated_at BEFORE UPDATE ON user_complete_profile
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON attendance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_leaves_updated_at BEFORE UPDATE ON leaves
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_codes_updated_at BEFORE UPDATE ON codes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();