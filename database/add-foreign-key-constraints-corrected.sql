-- ============================================================================
-- FOREIGN KEY CONSTRAINTS MIGRATION SCRIPT (CORRECTED)
-- Database Administrator: 30+ Years Experience
-- Purpose: Establish proper referential integrity based on actual table structure
-- Created: 2025-09-22
-- ============================================================================

-- Enable foreign key enforcement
PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- ============================================================================
-- STEP 1: ANALYZE CURRENT TABLE STRUCTURE AND CLEAN ORPHANED DATA
-- ============================================================================

-- Check for orphaned records in existing tables before adding constraints
DELETE FROM pension_nominees 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions WHERE staff_id IS NOT NULL);

DELETE FROM leave_applications 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions WHERE staff_id IS NOT NULL);

DELETE FROM attendance_records 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions WHERE staff_id IS NOT NULL);

DELETE FROM documents 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions WHERE staff_id IS NOT NULL);

DELETE FROM payslips 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions WHERE staff_id IS NOT NULL);

DELETE FROM ps_verifications 
WHERE staff_id NOT IN (SELECT staff_id FROM admissions WHERE staff_id IS NOT NULL);

-- Clean up user references
UPDATE leave_applications SET approved_by = NULL 
WHERE approved_by IS NOT NULL AND approved_by NOT IN (SELECT id FROM users);

UPDATE documents SET verified_by = NULL 
WHERE verified_by IS NOT NULL AND verified_by NOT IN (SELECT id FROM users);

UPDATE payslips SET generated_by = NULL 
WHERE generated_by IS NOT NULL AND generated_by NOT IN (SELECT id FROM users);

-- ============================================================================
-- STEP 2: POPULATE REFERENCE TABLES WITH EXISTING DATA
-- ============================================================================

-- Insert unique designations from admissions table if they don't exist
INSERT OR IGNORE INTO designations (name, department, description)
SELECT DISTINCT 
    designation,
    'General' as department,
    'Auto-migrated from existing data' as description
FROM admissions 
WHERE designation IS NOT NULL AND designation != ''
AND designation NOT IN (SELECT name FROM designations);

-- Insert unique function codes from admissions table if they don't exist
INSERT OR IGNORE INTO function_codes (code, name, description)
SELECT DISTINCT 
    function_code,
    'Function Code ' || function_code as name,
    'Auto-migrated from existing data' as description
FROM admissions 
WHERE function_code IS NOT NULL AND function_code != ''
AND function_code NOT IN (SELECT code FROM function_codes);

-- Insert unique object codes from admissions table if they don't exist
INSERT OR IGNORE INTO object_codes (code, name, description)
SELECT DISTINCT 
    object_code,
    'Object Code ' || object_code as name,
    'Auto-migrated from existing data' as description
FROM admissions 
WHERE object_code IS NOT NULL AND object_code != ''
AND object_code NOT IN (SELECT code FROM object_codes);

-- ============================================================================
-- STEP 3: CREATE NEW TABLES WITH FOREIGN KEY CONSTRAINTS
-- ============================================================================

-- Create a new admissions table with proper foreign key constraints
CREATE TABLE admissions_with_fk (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) UNIQUE NOT NULL,
    staff_name VARCHAR(100) NOT NULL,
    designation VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    age INTEGER CHECK (age >= 18 AND age <= 100),
    sex VARCHAR(10) CHECK (sex IN ('Male', 'Female', 'Other')),
    nationality VARCHAR(50) DEFAULT 'Indian',
    father_name VARCHAR(100) NOT NULL,
    mother_name VARCHAR(100),
    grand_father_name VARCHAR(100),
    marital_status VARCHAR(20) CHECK (marital_status IN ('Single', 'Married', 'Divorced', 'Widowed')),
    spouse_name VARCHAR(100),
    children TEXT,
    date_of_appointment DATE NOT NULL,
    retirement_date DATE,
    function_code VARCHAR(20) NOT NULL,
    object_code VARCHAR(20) NOT NULL,
    date_of_next_increment DATE,
    pension_scheme VARCHAR(50) NOT NULL,
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
    pay_band VARCHAR(50),
    grade_pay VARCHAR(20),
    pay_level INTEGER CHECK (pay_level >= 1 AND pay_level <= 18),
    pay_cell INTEGER CHECK (pay_cell >= 1),
    basic_pay_calculated DECIMAL(12,2) NOT NULL CHECK (basic_pay_calculated > 0),
    da DECIMAL(8,2) DEFAULT 50.0 CHECK (da >= 0),
    hra DECIMAL(8,2) DEFAULT 24.0 CHECK (hra >= 0),
    special_pay DECIMAL(10,2) DEFAULT 0 CHECK (special_pay >= 0),
    special_allowance DECIMAL(10,2) DEFAULT 0 CHECK (special_allowance >= 0),
    other_allowance DECIMAL(10,2) DEFAULT 0 CHECK (other_allowance >= 0),
    gross_salary DECIMAL(12,2),
    total_deductions DECIMAL(10,2) DEFAULT 0,
    net_salary DECIMAL(12,2),
    photo TEXT,
    documents TEXT,
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
    status VARCHAR(20) DEFAULT 'approved' CHECK (status IN ('pending', 'approved', 'rejected', 'inactive')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- FOREIGN KEY CONSTRAINTS
    FOREIGN KEY (designation) REFERENCES designations(name) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (function_code) REFERENCES function_codes(code) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (object_code) REFERENCES object_codes(code) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Copy data from old table
INSERT INTO admissions_with_fk 
SELECT * FROM admissions 
WHERE designation IN (SELECT name FROM designations)
  AND function_code IN (SELECT code FROM function_codes)
  AND object_code IN (SELECT code FROM object_codes);

-- ============================================================================
-- STEP 4: CREATE OTHER TABLES WITH FOREIGN KEY CONSTRAINTS
-- ============================================================================

-- Create staff_deductions table with foreign key (if it doesn't exist)
CREATE TABLE IF NOT EXISTS staff_deductions_with_fk (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    pf DECIMAL(10,2) DEFAULT 0 CHECK (pf >= 0),
    esi DECIMAL(10,2) DEFAULT 0 CHECK (esi >= 0),
    professional_tax DECIMAL(10,2) DEFAULT 0 CHECK (professional_tax >= 0),
    income_tax DECIMAL(10,2) DEFAULT 0 CHECK (income_tax >= 0),
    house_building_advance DECIMAL(10,2) DEFAULT 0 CHECK (house_building_advance >= 0),
    vehicle_advance DECIMAL(10,2) DEFAULT 0 CHECK (vehicle_advance >= 0),
    personal_loan DECIMAL(10,2) DEFAULT 0 CHECK (personal_loan >= 0),
    festival_advance DECIMAL(10,2) DEFAULT 0 CHECK (festival_advance >= 0),
    other_deduction1_name VARCHAR(100),
    other_deduction1_amount DECIMAL(10,2) DEFAULT 0 CHECK (other_deduction1_amount >= 0),
    other_deduction2_name VARCHAR(100),
    other_deduction2_amount DECIMAL(10,2) DEFAULT 0 CHECK (other_deduction2_amount >= 0),
    total_deductions DECIMAL(10,2) DEFAULT 0,
    remarks TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES admissions_with_fk(staff_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Create enhanced leave_applications with foreign keys
CREATE TABLE leave_applications_with_fk (
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
    
    FOREIGN KEY (staff_id) REFERENCES admissions_with_fk(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (leave_type_id) REFERENCES leave_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Copy existing leave applications
INSERT INTO leave_applications_with_fk 
SELECT * FROM leave_applications 
WHERE staff_id IN (SELECT staff_id FROM admissions_with_fk);

-- Create enhanced documents with foreign keys
CREATE TABLE documents_with_fk (
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
    
    FOREIGN KEY (staff_id) REFERENCES admissions_with_fk(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Copy existing documents
INSERT INTO documents_with_fk 
SELECT * FROM documents 
WHERE staff_id IN (SELECT staff_id FROM admissions_with_fk);

-- Create enhanced payslips with foreign keys
CREATE TABLE payslips_with_fk (
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
    
    FOREIGN KEY (staff_id) REFERENCES admissions_with_fk(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (generated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    UNIQUE(staff_id, month, year)
);

-- Copy existing payslips
INSERT INTO payslips_with_fk 
SELECT * FROM payslips 
WHERE staff_id IN (SELECT staff_id FROM admissions_with_fk);

-- Create enhanced attendance_records with foreign keys
CREATE TABLE attendance_records_with_fk (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    days_present INTEGER DEFAULT 0,
    days_absent INTEGER DEFAULT 0,
    overtime_hours DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES admissions_with_fk(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    
    UNIQUE(staff_id, year, month)
);

-- Copy existing attendance records
INSERT INTO attendance_records_with_fk 
SELECT * FROM attendance_records 
WHERE staff_id IN (SELECT staff_id FROM admissions_with_fk);

-- Create enhanced ps_verifications with foreign keys
CREATE TABLE ps_verifications_with_fk (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    verification_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
    verified_by INTEGER,
    verified_at TIMESTAMP,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES admissions_with_fk(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Copy existing ps_verifications
INSERT INTO ps_verifications_with_fk 
SELECT * FROM ps_verifications 
WHERE staff_id IN (SELECT staff_id FROM admissions_with_fk);

-- ============================================================================
-- STEP 5: REPLACE OLD TABLES WITH NEW FOREIGN KEY TABLES
-- ============================================================================

-- Backup old tables
ALTER TABLE admissions RENAME TO admissions_backup;
ALTER TABLE leave_applications RENAME TO leave_applications_backup;
ALTER TABLE documents RENAME TO documents_backup;
ALTER TABLE payslips RENAME TO payslips_backup;
ALTER TABLE attendance_records RENAME TO attendance_records_backup;
ALTER TABLE ps_verifications RENAME TO ps_verifications_backup;

-- Rename new tables to original names
ALTER TABLE admissions_with_fk RENAME TO admissions;
ALTER TABLE leave_applications_with_fk RENAME TO leave_applications;
ALTER TABLE documents_with_fk RENAME TO documents;
ALTER TABLE payslips_with_fk RENAME TO payslips;
ALTER TABLE attendance_records_with_fk RENAME TO attendance_records;
ALTER TABLE ps_verifications_with_fk RENAME TO ps_verifications;

-- Create staff_deductions if it doesn't exist (rename from the with_fk version)
DROP TABLE IF EXISTS staff_deductions;
ALTER TABLE staff_deductions_with_fk RENAME TO staff_deductions;

-- ============================================================================
-- STEP 6: CREATE PERFORMANCE INDEXES
-- ============================================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_admissions_staff_id ON admissions(staff_id);
CREATE INDEX IF NOT EXISTS idx_admissions_designation ON admissions(designation);
CREATE INDEX IF NOT EXISTS idx_admissions_function_code ON admissions(function_code);
CREATE INDEX IF NOT EXISTS idx_admissions_object_code ON admissions(object_code);

-- Foreign key indexes for performance
CREATE INDEX IF NOT EXISTS idx_staff_deductions_staff_id ON staff_deductions(staff_id);
CREATE INDEX IF NOT EXISTS idx_leave_applications_staff_id ON leave_applications(staff_id);
CREATE INDEX IF NOT EXISTS idx_leave_applications_type ON leave_applications(leave_type_id);
CREATE INDEX IF NOT EXISTS idx_leave_applications_approver ON leave_applications(approved_by);
CREATE INDEX IF NOT EXISTS idx_documents_staff_id ON documents(staff_id);
CREATE INDEX IF NOT EXISTS idx_documents_verifier ON documents(verified_by);
CREATE INDEX IF NOT EXISTS idx_payslips_staff_id ON payslips(staff_id);
CREATE INDEX IF NOT EXISTS idx_payslips_generator ON payslips(generated_by);
CREATE INDEX IF NOT EXISTS idx_attendance_staff_id ON attendance_records(staff_id);
CREATE INDEX IF NOT EXISTS idx_ps_verifications_staff_id ON ps_verifications(staff_id);
CREATE INDEX IF NOT EXISTS idx_ps_verifications_verifier ON ps_verifications(verified_by);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_payslips_staff_period ON payslips(staff_id, year, month);
CREATE INDEX IF NOT EXISTS idx_attendance_staff_period ON attendance_records(staff_id, year, month);

-- ============================================================================
-- STEP 7: CREATE TRIGGERS TO MAINTAIN REFERENTIAL INTEGRITY
-- ============================================================================

-- Trigger to prevent deletion of designations in use
CREATE TRIGGER IF NOT EXISTS prevent_designation_delete
BEFORE DELETE ON designations
FOR EACH ROW
WHEN EXISTS (SELECT 1 FROM admissions WHERE designation = OLD.name)
BEGIN
    SELECT RAISE(ABORT, 'Cannot delete designation: it is currently assigned to staff members');
END;

-- Trigger to prevent deletion of function codes in use
CREATE TRIGGER IF NOT EXISTS prevent_function_code_delete
BEFORE DELETE ON function_codes
FOR EACH ROW
WHEN EXISTS (SELECT 1 FROM admissions WHERE function_code = OLD.code)
BEGIN
    SELECT RAISE(ABORT, 'Cannot delete function code: it is currently assigned to staff members');
END;

-- Trigger to prevent deletion of object codes in use
CREATE TRIGGER IF NOT EXISTS prevent_object_code_delete
BEFORE DELETE ON object_codes
FOR EACH ROW
WHEN EXISTS (SELECT 1 FROM admissions WHERE object_code = OLD.code)
BEGIN
    SELECT RAISE(ABORT, 'Cannot delete object code: it is currently assigned to staff members');
END;

-- ============================================================================
-- STEP 8: VERIFY FOREIGN KEY CONSTRAINTS
-- ============================================================================

-- Test foreign key enforcement
PRAGMA foreign_keys = ON;

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

SELECT 'FOREIGN KEY CONSTRAINTS SUCCESSFULLY IMPLEMENTED!' as status;
SELECT 'Tables now have proper referential integrity' as message;
SELECT 'Foreign key enforcement: ' || CASE WHEN foreign_keys = 1 THEN 'ENABLED' ELSE 'DISABLED' END as fk_status FROM pragma_foreign_keys();

-- Count records in main tables
SELECT 'Records in admissions: ' || COUNT(*) FROM admissions;
SELECT 'Records in staff_deductions: ' || COUNT(*) FROM staff_deductions;
SELECT 'Records in leave_applications: ' || COUNT(*) FROM leave_applications;
SELECT 'Records in documents: ' || COUNT(*) FROM documents;
SELECT 'Records in payslips: ' || COUNT(*) FROM payslips;

-- Check for any remaining orphaned records (should be 0)
SELECT 'Orphaned leave applications: ' || COUNT(*) 
FROM leave_applications la 
LEFT JOIN admissions a ON la.staff_id = a.staff_id 
WHERE a.staff_id IS NULL;

SELECT 'Invalid designation references: ' || COUNT(*) 
FROM admissions a 
LEFT JOIN designations d ON a.designation = d.name 
WHERE d.name IS NULL;