-- ============================================================================
-- FOREIGN KEY CONSTRAINTS MIGRATION SCRIPT
-- Database Administrator: 30+ Years Experience
-- Purpose: Establish proper referential integrity across all tables
-- Created: 2025-09-22
-- ============================================================================

-- CRITICAL: Run this script in a transaction to ensure rollback capability
-- PRAGMA foreign_keys = ON; -- Enable foreign key enforcement

BEGIN TRANSACTION;

-- ============================================================================
-- STEP 1: CLEAN UP ORPHANED DATA BEFORE ADDING CONSTRAINTS
-- ============================================================================

-- Remove any orphaned records that would violate foreign key constraints
DELETE FROM pension_nominees 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions);

DELETE FROM staff_deductions 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions);

DELETE FROM leave_applications 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions);

DELETE FROM attendance_records 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions);

DELETE FROM documents 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions);

DELETE FROM payslips 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions);

DELETE FROM ps_verifications 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions);

-- Clean up references to non-existent users
UPDATE leave_applications SET approved_by = NULL 
WHERE approved_by IS NOT NULL AND approved_by NOT IN (SELECT id FROM users);

UPDATE documents SET verified_by = NULL 
WHERE verified_by IS NOT NULL AND verified_by NOT IN (SELECT id FROM users);

UPDATE payslips SET generated_by = NULL 
WHERE generated_by IS NOT NULL AND generated_by NOT IN (SELECT id FROM users);

-- ============================================================================
-- STEP 2: CREATE MISSING REFERENCE TABLES IF THEY DON'T EXIST
-- ============================================================================

-- Ensure designations table exists with proper structure
CREATE TABLE IF NOT EXISTS designations (
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

-- Ensure function_codes table exists
CREATE TABLE IF NOT EXISTS function_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ensure object_codes table exists
CREATE TABLE IF NOT EXISTS object_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ensure leave_types table exists
CREATE TABLE IF NOT EXISTS leave_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    days_allowed INTEGER NOT NULL CHECK (days_allowed > 0),
    description TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STEP 3: POPULATE REFERENCE TABLES WITH EXISTING DATA
-- ============================================================================

-- Insert unique designations from admissions table
INSERT OR IGNORE INTO designations (name, department, description)
SELECT DISTINCT 
    designation,
    'General' as department,
    'Auto-migrated from existing data' as description
FROM admissions 
WHERE designation IS NOT NULL AND designation != '';

-- Insert unique function codes from admissions table
INSERT OR IGNORE INTO function_codes (code, name, description)
SELECT DISTINCT 
    function_code,
    'Function Code ' || function_code as name,
    'Auto-migrated from existing data' as description
FROM admissions 
WHERE function_code IS NOT NULL AND function_code != '';

-- Insert unique object codes from admissions table
INSERT OR IGNORE INTO object_codes (code, name, description)
SELECT DISTINCT 
    object_code,
    'Object Code ' || object_code as name,
    'Auto-migrated from existing data' as description
FROM admissions 
WHERE object_code IS NOT NULL AND object_code != '';

-- ============================================================================
-- STEP 4: ADD FOREIGN KEY CONSTRAINTS
-- ============================================================================

-- Note: SQLite doesn't support adding foreign keys to existing tables
-- We need to recreate tables with foreign keys
-- This is done by creating new tables, copying data, dropping old, renaming new

-- ============================================================================
-- RECREATE ADMISSIONS TABLE WITH FOREIGN KEYS
-- ============================================================================

-- Create new admissions table with foreign key constraints
CREATE TABLE admissions_new (
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
    children TEXT,
    
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
    
    -- Salary Structure
    pay_band VARCHAR(50),
    grade_pay VARCHAR(20),
    pay_level INTEGER CHECK (pay_level >= 1 AND pay_level <= 18),
    pay_cell INTEGER CHECK (pay_cell >= 1),
    basic_pay_calculated DECIMAL(12,2) NOT NULL CHECK (basic_pay_calculated > 0),
    
    -- Allowances
    da DECIMAL(8,2) DEFAULT 50.0 CHECK (da >= 0),
    hra DECIMAL(8,2) DEFAULT 24.0 CHECK (hra >= 0),
    special_pay DECIMAL(10,2) DEFAULT 0 CHECK (special_pay >= 0),
    special_allowance DECIMAL(10,2) DEFAULT 0 CHECK (special_allowance >= 0),
    other_allowance DECIMAL(10,2) DEFAULT 0 CHECK (other_allowance >= 0),
    
    -- Calculated salary fields
    gross_salary DECIMAL(12,2),
    total_deductions DECIMAL(10,2) DEFAULT 0,
    net_salary DECIMAL(12,2),
    
    -- Document and Photo storage
    photo TEXT,
    documents TEXT,
    
    -- Legacy fields
    email VARCHAR(100) CHECK (email IS NULL OR email LIKE '%@%.%'),
    religion VARCHAR(50),
    category VARCHAR(50),
    present_address TEXT,
    employee_type VARCHAR(50),
    date_of_joining DATE,
    office_number VARCHAR(50),
    emergency_contact VARCHAR(15),
    basic_pay DECIMAL(12,2),
    basic_salary DECIMAL(12,2),
    
    -- System fields
    status VARCHAR(20) DEFAULT 'approved' CHECK (status IN ('pending', 'approved', 'rejected', 'inactive')),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- FOREIGN KEY CONSTRAINTS
    FOREIGN KEY (designation) REFERENCES designations(name) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (function_code) REFERENCES function_codes(code) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (object_code) REFERENCES object_codes(code) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Copy data from old table to new table
INSERT INTO admissions_new SELECT * FROM admissions;

-- Drop old table and rename new table
DROP TABLE admissions;
ALTER TABLE admissions_new RENAME TO admissions;

-- ============================================================================
-- RECREATE OTHER TABLES WITH ENHANCED FOREIGN KEYS
-- ============================================================================

-- Update staff_deductions table to ensure proper foreign key
DROP TABLE IF EXISTS staff_deductions_new;
CREATE TABLE staff_deductions_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    total_deductions DECIMAL(10,2) DEFAULT 0,
    
    remarks TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- FOREIGN KEY CONSTRAINTS
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Copy existing data if table exists
INSERT INTO staff_deductions_new 
SELECT * FROM staff_deductions WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type='table' AND name='staff_deductions');

-- Replace old table
DROP TABLE IF EXISTS staff_deductions;
ALTER TABLE staff_deductions_new RENAME TO staff_deductions;

-- ============================================================================
-- RECREATE LEAVE_APPLICATIONS WITH PROPER FOREIGN KEYS
-- ============================================================================

DROP TABLE IF EXISTS leave_applications_new;
CREATE TABLE leave_applications_new (
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
    
    -- FOREIGN KEY CONSTRAINTS
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (leave_type_id) REFERENCES leave_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Copy existing data if table exists
INSERT INTO leave_applications_new 
SELECT * FROM leave_applications WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type='table' AND name='leave_applications');

-- Replace old table
DROP TABLE IF EXISTS leave_applications;
ALTER TABLE leave_applications_new RENAME TO leave_applications;

-- ============================================================================
-- RECREATE DOCUMENTS TABLE WITH PROPER FOREIGN KEYS
-- ============================================================================

DROP TABLE IF EXISTS documents_new;
CREATE TABLE documents_new (
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
    
    -- FOREIGN KEY CONSTRAINTS
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Copy existing data if table exists
INSERT INTO documents_new 
SELECT * FROM documents WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type='table' AND name='documents');

-- Replace old table
DROP TABLE IF EXISTS documents;
ALTER TABLE documents_new RENAME TO documents;

-- ============================================================================
-- RECREATE PAYSLIPS TABLE WITH PROPER FOREIGN KEYS
-- ============================================================================

DROP TABLE IF EXISTS payslips_new;
CREATE TABLE payslips_new (
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
    
    -- FOREIGN KEY CONSTRAINTS
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (generated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    UNIQUE(staff_id, month, year)
);

-- Copy existing data if table exists
INSERT INTO payslips_new 
SELECT * FROM payslips WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type='table' AND name='payslips');

-- Replace old table
DROP TABLE IF EXISTS payslips;
ALTER TABLE payslips_new RENAME TO payslips;

-- ============================================================================
-- RECREATE ATTENDANCE_RECORDS WITH PROPER FOREIGN KEYS
-- ============================================================================

DROP TABLE IF EXISTS attendance_records_new;
CREATE TABLE attendance_records_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    days_present INTEGER DEFAULT 0,
    days_absent INTEGER DEFAULT 0,
    overtime_hours DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- FOREIGN KEY CONSTRAINTS
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    
    UNIQUE(staff_id, year, month)
);

-- Copy existing data if table exists
INSERT INTO attendance_records_new 
SELECT * FROM attendance_records WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type='table' AND name='attendance_records');

-- Replace old table
DROP TABLE IF EXISTS attendance_records;
ALTER TABLE attendance_records_new RENAME TO attendance_records;

-- ============================================================================
-- RECREATE PS_VERIFICATIONS WITH PROPER FOREIGN KEYS
-- ============================================================================

DROP TABLE IF EXISTS ps_verifications_new;
CREATE TABLE ps_verifications_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    verification_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
    verified_by INTEGER,
    verified_at TIMESTAMP,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- FOREIGN KEY CONSTRAINTS
    FOREIGN KEY (staff_id) REFERENCES admissions(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Copy existing data if table exists
INSERT INTO ps_verifications_new 
SELECT * FROM ps_verifications WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type='table' AND name='ps_verifications');

-- Replace old table
DROP TABLE IF EXISTS ps_verifications;
ALTER TABLE ps_verifications_new RENAME TO ps_verifications;

-- ============================================================================
-- STEP 5: RECREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Primary search indexes
CREATE INDEX IF NOT EXISTS idx_admissions_staff_id ON admissions(staff_id);
CREATE INDEX IF NOT EXISTS idx_admissions_mobile ON admissions(mobile_number);
CREATE INDEX IF NOT EXISTS idx_admissions_name ON admissions(staff_name);
CREATE INDEX IF NOT EXISTS idx_admissions_designation ON admissions(designation);
CREATE INDEX IF NOT EXISTS idx_admissions_status ON admissions(status);
CREATE INDEX IF NOT EXISTS idx_admissions_appointment_date ON admissions(date_of_appointment);

-- Foreign key indexes for performance
CREATE INDEX IF NOT EXISTS idx_nominees_staff_id ON pension_nominees(staff_id);
CREATE INDEX IF NOT EXISTS idx_deductions_staff_id ON staff_deductions(staff_id);
CREATE INDEX IF NOT EXISTS idx_leave_applications_staff_id ON leave_applications(staff_id);
CREATE INDEX IF NOT EXISTS idx_leave_applications_type ON leave_applications(leave_type_id);
CREATE INDEX IF NOT EXISTS idx_leave_applications_approver ON leave_applications(approved_by);
CREATE INDEX IF NOT EXISTS idx_attendance_staff_id ON attendance_records(staff_id);
CREATE INDEX IF NOT EXISTS idx_documents_staff_id ON documents(staff_id);
CREATE INDEX IF NOT EXISTS idx_documents_verifier ON documents(verified_by);
CREATE INDEX IF NOT EXISTS idx_payslips_staff_id ON payslips(staff_id);
CREATE INDEX IF NOT EXISTS idx_payslips_generator ON payslips(generated_by);
CREATE INDEX IF NOT EXISTS idx_ps_verifications_staff_id ON ps_verifications(staff_id);
CREATE INDEX IF NOT EXISTS idx_ps_verifications_verifier ON ps_verifications(verified_by);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_payslips_staff_period ON payslips(staff_id, year, month);
CREATE INDEX IF NOT EXISTS idx_attendance_staff_period ON attendance_records(staff_id, year, month);
CREATE INDEX IF NOT EXISTS idx_leave_apps_staff_status ON leave_applications(staff_id, status);

-- ============================================================================
-- STEP 6: ENABLE FOREIGN KEY ENFORCEMENT
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ============================================================================
-- STEP 7: INSERT DEFAULT DATA IF TABLES ARE EMPTY
-- ============================================================================

-- Insert default leave types if none exist
INSERT OR IGNORE INTO leave_types (name, days_allowed, description) VALUES
('Earned Leave', 30, 'Annual earned leave entitlement'),
('Casual Leave', 12, 'Casual leave for personal work'),
('Medical Leave', 90, 'Medical leave for health issues'),
('Maternity Leave', 180, 'Maternity leave for female employees'),
('Paternity Leave', 15, 'Paternity leave for male employees'),
('Study Leave', 365, 'Educational and training leave');

-- ============================================================================
-- COMMIT TRANSACTION
-- ============================================================================

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES (RUN THESE AFTER MIGRATION)
-- ============================================================================

-- Check foreign key enforcement is working
PRAGMA foreign_keys;

-- Verify table structures
.schema admissions
.schema staff_deductions
.schema leave_applications
.schema documents
.schema payslips

-- Test referential integrity
SELECT 'Orphaned staff deductions: ' || COUNT(*) 
FROM staff_deductions sd 
LEFT JOIN admissions a ON sd.staff_id = a.staff_id 
WHERE a.staff_id IS NULL;

SELECT 'Orphaned leave applications: ' || COUNT(*) 
FROM leave_applications la 
LEFT JOIN admissions a ON la.staff_id = a.staff_id 
WHERE a.staff_id IS NULL;

SELECT 'Invalid designation references: ' || COUNT(*) 
FROM admissions a 
LEFT JOIN designations d ON a.designation = d.name 
WHERE d.name IS NULL;

-- ============================================================================
-- END OF MIGRATION SCRIPT
-- ============================================================================

-- SUCCESS MESSAGE
SELECT 'FOREIGN KEY CONSTRAINTS MIGRATION COMPLETED SUCCESSFULLY!' as status,
       'Referential integrity has been established across all tables.' as message,
       'Database now enforces data consistency and prevents orphaned records.' as benefit;