-- PostgreSQL Initialization Script for CBA Portal
-- This script will be automatically executed when PostgreSQL container starts

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create custom types
CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'operator', 'user');
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE admission_status AS ENUM ('pending', 'approved', 'rejected', 'inactive');
CREATE TYPE gender AS ENUM ('Male', 'Female', 'Other');
CREATE TYPE marital_status AS ENUM ('Single', 'Married', 'Divorced', 'Widowed');
CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'rejected');
CREATE TYPE notification_type AS ENUM ('info', 'warning', 'error', 'success');
CREATE TYPE audit_action AS ENUM ('INSERT', 'UPDATE', 'DELETE');

-- Create database schema message
INSERT INTO pg_stat_statements_info (dealloc) VALUES (0);
COMMENT ON DATABASE cba_portal IS 'CBA Portal Database - Initialized for Docker deployment';