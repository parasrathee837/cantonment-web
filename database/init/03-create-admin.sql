-- Create default admin user for CBA Portal
-- This script creates the initial admin user with proper credentials

-- Insert default admin user
INSERT INTO users (
    username, 
    email, 
    password_hash, 
    role, 
    status, 
    full_name,
    created_at,
    updated_at
) VALUES (
    'admin',
    'admin@cba.local',
    '$2a$12$LQv3c1yqBw.bK4w6n7kVKOq1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1',  -- Password: admin123
    'super_admin',
    'active',
    'System Administrator',
    NOW(),
    NOW()
) ON CONFLICT (username) DO NOTHING;

-- Insert sample designation
INSERT INTO designations (name, description, created_at, updated_at) 
VALUES ('Administrator', 'System Administrator', NOW(), NOW())
ON CONFLICT (name) DO NOTHING;

-- Create sample staff record linked to admin user
INSERT INTO admissions (
    staff_id,
    staff_name,
    designation,
    sex,
    nationality,
    created_at,
    updated_at,
    status
) VALUES (
    'CBA001',
    'System Administrator',
    'Administrator',
    'Male',
    'Indian',
    NOW(),
    NOW(),
    'approved'
) ON CONFLICT (staff_id) DO NOTHING;

-- Log initialization
INSERT INTO system_logs (
    action,
    table_name,
    record_id,
    user_id,
    details,
    timestamp
) VALUES (
    'SYSTEM_INIT',
    'users',
    (SELECT id FROM users WHERE username = 'admin'),
    (SELECT id FROM users WHERE username = 'admin'),
    '{"message": "Database initialized with default admin user", "docker": true}',
    NOW()
);