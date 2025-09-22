-- Cantonment Board Administration System Database Schema

CREATE DATABASE IF NOT EXISTS cantonment_board;
USE cantonment_board;

-- Users table for authentication
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'user', 'operator') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Designations table
CREATE TABLE designations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Nationalities table
CREATE TABLE nationalities (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    code VARCHAR(3),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admissions table
CREATE TABLE admissions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    father_name VARCHAR(100) NOT NULL,
    nationality_id INT,
    address TEXT NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    designation_id INT,
    photo_path VARCHAR(255),
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    admission_date DATE,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (nationality_id) REFERENCES nationalities(id),
    FOREIGN KEY (designation_id) REFERENCES designations(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- System settings table
CREATE TABLE system_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Audit log table
CREATE TABLE audit_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(50),
    record_id INT,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Insert default data
INSERT INTO nationalities (name, code) VALUES
('Indian', 'IND'),
('Pakistani', 'PAK'),
('Bangladeshi', 'BGD'),
('Nepalese', 'NPL'),
('Sri Lankan', 'LKA'),
('Other', 'OTH');

INSERT INTO designations (name, department, description) VALUES
('Chief Executive Officer', 'Administration', 'Head of cantonment board'),
('Executive Officer', 'Administration', 'Senior administrative officer'),
('Assistant Engineer', 'Engineering', 'Engineering department assistant'),
('Junior Engineer', 'Engineering', 'Junior level engineer'),
('Accountant', 'Finance', 'Financial operations'),
('Medical Officer', 'Health', 'Healthcare services'),
('Security Officer', 'Security', 'Security and safety'),
('Sanitation Inspector', 'Health', 'Sanitation oversight'),
('Tax Collector', 'Finance', 'Revenue collection'),
('Store Keeper', 'Administration', 'Inventory management');

INSERT INTO system_settings (setting_key, setting_value, description) VALUES
('cantonment_name', 'Cantonment Board Ambala', 'Name of the cantonment board'),
('cantonment_code', 'CBA', 'Short code for the cantonment'),
('contact_email', 'admin@cba.gov.in', 'Official contact email'),
('contact_phone', '+91-1234567890', 'Official contact phone'),
('address', 'Cantonment Board Office, Ambala Cantt', 'Official address'),
('max_file_size', '5242880', 'Maximum file upload size in bytes (5MB)'),
('session_timeout', '1440', 'Session timeout in minutes (24 hours)');

-- Create default admin user (password: admin123)
INSERT INTO users (username, password, role) VALUES
('admin', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPjjJx/rOOmOC', 'admin');

-- Create indexes for better performance
CREATE INDEX idx_admissions_status ON admissions(status);
CREATE INDEX idx_admissions_created_at ON admissions(created_at);
CREATE INDEX idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at);