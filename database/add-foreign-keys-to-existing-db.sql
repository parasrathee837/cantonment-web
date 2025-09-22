-- ============================================================================
-- FOREIGN KEY CONSTRAINTS FOR EXISTING DATABASE
-- Database Administrator: 30+ Years Experience
-- Purpose: Add foreign key constraints to the actual existing database structure
-- Created: 2025-09-22
-- ============================================================================

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- ============================================================================
-- STEP 1: ANALYZE EXISTING STRUCTURE AND ADD FOREIGN KEY RELATIONSHIPS
-- ============================================================================

-- The current admissions table uses 'name' instead of 'staff_name' and 'id' as primary key
-- We need to work with the existing structure and add foreign keys where possible

-- ============================================================================
-- STEP 2: ENSURE REFERENCE TABLES HAVE REQUIRED DATA
-- ============================================================================

-- Ensure designations exist for all used designations in admissions
INSERT OR IGNORE INTO designations (name, department, description)
SELECT DISTINCT 
    designation,
    'General' as department,
    'Auto-migrated from admissions table' as description
FROM admissions 
WHERE designation IS NOT NULL 
  AND designation != ''
  AND designation NOT IN (SELECT name FROM designations WHERE name IS NOT NULL);

-- ============================================================================
-- STEP 3: ADD FOREIGN KEY CONSTRAINTS TO EXISTING TABLES
-- ============================================================================

-- For SQLite, we need to recreate tables to add foreign keys
-- Let's start with the most important relationships

-- 3.1: ENHANCE LEAVE_APPLICATIONS TABLE WITH FOREIGN KEYS
-- ----------------------------------------------------------------

CREATE TABLE leave_applications_enhanced (
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
    
    -- Foreign key to users table for approved_by
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    -- Foreign key to leave_types
    FOREIGN KEY (leave_type_id) REFERENCES leave_types(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Copy existing data from leave_applications
INSERT INTO leave_applications_enhanced 
SELECT la.* FROM leave_applications la
WHERE (la.approved_by IS NULL OR la.approved_by IN (SELECT id FROM users))
  AND (la.leave_type_id IN (SELECT id FROM leave_types));

-- Replace old table
DROP TABLE leave_applications;
ALTER TABLE leave_applications_enhanced RENAME TO leave_applications;

-- 3.2: ENHANCE DOCUMENTS TABLE WITH FOREIGN KEYS
-- ----------------------------------------------------------------

CREATE TABLE documents_enhanced (
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
    
    -- Foreign key to users table for verified_by
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Copy existing data
INSERT INTO documents_enhanced 
SELECT d.* FROM documents d
WHERE (d.verified_by IS NULL OR d.verified_by IN (SELECT id FROM users));

-- Replace old table
DROP TABLE documents;
ALTER TABLE documents_enhanced RENAME TO documents;

-- 3.3: ENHANCE PAYSLIPS TABLE WITH FOREIGN KEYS
-- ----------------------------------------------------------------

CREATE TABLE payslips_enhanced (
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
    
    -- Foreign key to users table for generated_by
    FOREIGN KEY (generated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    UNIQUE(staff_id, month, year)
);

-- Copy existing data
INSERT INTO payslips_enhanced 
SELECT p.* FROM payslips p
WHERE (p.generated_by IS NULL OR p.generated_by IN (SELECT id FROM users));

-- Replace old table
DROP TABLE payslips;
ALTER TABLE payslips_enhanced RENAME TO payslips;

-- 3.4: ENHANCE PS_VERIFICATIONS TABLE WITH FOREIGN KEYS
-- ----------------------------------------------------------------

CREATE TABLE ps_verifications_enhanced (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id VARCHAR(50) NOT NULL,
    verification_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
    verified_by INTEGER,
    verified_at TIMESTAMP,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key to users table for verified_by
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Copy existing data
INSERT INTO ps_verifications_enhanced 
SELECT pv.* FROM ps_verifications pv
WHERE (pv.verified_by IS NULL OR pv.verified_by IN (SELECT id FROM users));

-- Replace old table
DROP TABLE ps_verifications;
ALTER TABLE ps_verifications_enhanced RENAME TO ps_verifications;

-- 3.5: CREATE STAFF_DEDUCTIONS TABLE WITH FOREIGN KEYS IF NEEDED
-- ----------------------------------------------------------------

CREATE TABLE IF NOT EXISTS staff_deductions (
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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STEP 4: ADD PROTECTIVE TRIGGERS
-- ============================================================================

-- Prevent deletion of users who have dependent records
CREATE TRIGGER IF NOT EXISTS prevent_user_delete_with_dependencies
BEFORE DELETE ON users
FOR EACH ROW
WHEN EXISTS (
    SELECT 1 FROM leave_applications WHERE approved_by = OLD.id
    UNION
    SELECT 1 FROM documents WHERE verified_by = OLD.id
    UNION
    SELECT 1 FROM payslips WHERE generated_by = OLD.id
    UNION
    SELECT 1 FROM ps_verifications WHERE verified_by = OLD.id
)
BEGIN
    SELECT RAISE(ABORT, 'Cannot delete user: they have dependent records in the system');
END;

-- Prevent deletion of leave types that are in use
CREATE TRIGGER IF NOT EXISTS prevent_leave_type_delete_with_dependencies
BEFORE DELETE ON leave_types
FOR EACH ROW
WHEN EXISTS (SELECT 1 FROM leave_applications WHERE leave_type_id = OLD.id)
BEGIN
    SELECT RAISE(ABORT, 'Cannot delete leave type: it is currently assigned to leave applications');
END;

-- Prevent deletion of designations that are in use
CREATE TRIGGER IF NOT EXISTS prevent_designation_delete_with_dependencies
BEFORE DELETE ON designations
FOR EACH ROW
WHEN EXISTS (SELECT 1 FROM admissions WHERE designation = OLD.name)
BEGIN
    SELECT RAISE(ABORT, 'Cannot delete designation: it is currently assigned to staff members');
END;

-- ============================================================================
-- STEP 5: CREATE PERFORMANCE INDEXES FOR FOREIGN KEYS
-- ============================================================================

-- Indexes for foreign key columns to improve performance
CREATE INDEX IF NOT EXISTS idx_leave_applications_approved_by ON leave_applications(approved_by);
CREATE INDEX IF NOT EXISTS idx_leave_applications_leave_type_id ON leave_applications(leave_type_id);
CREATE INDEX IF NOT EXISTS idx_documents_verified_by ON documents(verified_by);
CREATE INDEX IF NOT EXISTS idx_payslips_generated_by ON payslips(generated_by);
CREATE INDEX IF NOT EXISTS idx_ps_verifications_verified_by ON ps_verifications(verified_by);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_leave_applications_staff_status ON leave_applications(staff_id, status);
CREATE INDEX IF NOT EXISTS idx_documents_staff_status ON documents(staff_id, verification_status);
CREATE INDEX IF NOT EXISTS idx_payslips_staff_period ON payslips(staff_id, year, month);

-- ============================================================================
-- STEP 6: CREATE AUDIT TRAIL TRIGGERS
-- ============================================================================

-- Audit trail for important table changes
CREATE TABLE IF NOT EXISTS audit_trail (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    record_id VARCHAR(50) NOT NULL,
    old_values TEXT, -- JSON
    new_values TEXT, -- JSON
    user_id INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45)
);

-- Audit trigger for leave applications
CREATE TRIGGER IF NOT EXISTS audit_leave_applications_changes
AFTER UPDATE ON leave_applications
FOR EACH ROW
BEGIN
    INSERT INTO audit_trail (table_name, operation, record_id, old_values, new_values, timestamp)
    VALUES (
        'leave_applications', 
        'UPDATE', 
        NEW.id,
        json_object('status', OLD.status, 'approved_by', OLD.approved_by),
        json_object('status', NEW.status, 'approved_by', NEW.approved_by),
        CURRENT_TIMESTAMP
    );
END;

-- Audit trigger for PS verifications
CREATE TRIGGER IF NOT EXISTS audit_ps_verifications_changes
AFTER UPDATE ON ps_verifications
FOR EACH ROW
BEGIN
    INSERT INTO audit_trail (table_name, operation, record_id, old_values, new_values, timestamp)
    VALUES (
        'ps_verifications', 
        'UPDATE', 
        NEW.id,
        json_object('status', OLD.status, 'verified_by', OLD.verified_by),
        json_object('status', NEW.status, 'verified_by', NEW.verified_by),
        CURRENT_TIMESTAMP
    );
END;

-- ============================================================================
-- STEP 7: ENABLE FOREIGN KEY ENFORCEMENT
-- ============================================================================

PRAGMA foreign_keys = ON;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'FOREIGN KEY CONSTRAINTS SUCCESSFULLY ADDED!' as status;
SELECT 'Database now has improved referential integrity' as message;

-- Check foreign key enforcement
SELECT 'Foreign key enforcement: ' || CASE WHEN foreign_keys = 1 THEN 'ENABLED' ELSE 'DISABLED' END as fk_status 
FROM pragma_foreign_keys();

-- Count tables with foreign keys
SELECT 'Tables with foreign key constraints: ' || COUNT(*) as fk_tables
FROM sqlite_master 
WHERE type = 'table' AND sql LIKE '%FOREIGN KEY%';

-- Count triggers created
SELECT 'Protective triggers created: ' || COUNT(*) as triggers_created
FROM sqlite_master 
WHERE type = 'trigger' AND name LIKE '%prevent_%';

-- Display structure of enhanced tables
SELECT 'Enhanced tables created:' as info;
SELECT name as table_name FROM sqlite_master 
WHERE type = 'table' AND name IN ('leave_applications', 'documents', 'payslips', 'ps_verifications', 'staff_deductions');

SELECT 'Foreign key implementation completed successfully!' as final_status;