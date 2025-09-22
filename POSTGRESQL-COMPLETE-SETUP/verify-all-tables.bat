@echo off
echo ===========================================
echo CBA Portal - Complete Database Verification
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Checking if all required tables exist...
echo.

REM Create a temporary verification script
(
echo -- CBA Portal Database Verification Script
echo -- Checks for all tables required by the application
echo.
echo SELECT 'VERIFICATION RESULTS:' as status;
echo.
echo -- Core User Tables
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'users'^) 
echo     THEN '[OK] users table exists' 
echo     ELSE '[MISSING] users table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'user_complete_profile'^) 
echo     THEN '[OK] user_complete_profile table exists' 
echo     ELSE '[MISSING] user_complete_profile table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles'^) 
echo     THEN '[OK] user_profiles table exists' 
echo     ELSE '[MISSING] user_profiles table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'user_sessions'^) 
echo     THEN '[OK] user_sessions table exists' 
echo     ELSE '[MISSING] user_sessions table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'user_activity'^) 
echo     THEN '[OK] user_activity table exists' 
echo     ELSE '[MISSING] user_activity table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'login_attempts'^) 
echo     THEN '[OK] login_attempts table exists' 
echo     ELSE '[MISSING] login_attempts table' END as status;
echo.
echo -- Staff/Admission Tables
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'admissions'^) 
echo     THEN '[OK] admissions table exists' 
echo     ELSE '[MISSING] admissions table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_personal'^) 
echo     THEN '[OK] staff_personal table exists' 
echo     ELSE '[MISSING] staff_personal table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_banking'^) 
echo     THEN '[OK] staff_banking table exists' 
echo     ELSE '[MISSING] staff_banking table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_documents'^) 
echo     THEN '[OK] staff_documents table exists' 
echo     ELSE '[MISSING] staff_documents table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_salary'^) 
echo     THEN '[OK] staff_salary table exists' 
echo     ELSE '[MISSING] staff_salary table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_deductions'^) 
echo     THEN '[OK] staff_deductions table exists' 
echo     ELSE '[MISSING] staff_deductions table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_deductions_comprehensive'^) 
echo     THEN '[OK] staff_deductions_comprehensive table exists' 
echo     ELSE '[MISSING] staff_deductions_comprehensive table' END as status;
echo.
echo -- Attendance Tables
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance'^) 
echo     THEN '[OK] attendance table exists' 
echo     ELSE '[MISSING] attendance table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance_records'^) 
echo     THEN '[OK] attendance_records table exists' 
echo     ELSE '[MISSING] attendance_records table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_attendance'^) 
echo     THEN '[OK] daily_attendance table exists' 
echo     ELSE '[MISSING] daily_attendance table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'holidays'^) 
echo     THEN '[OK] holidays table exists' 
echo     ELSE '[MISSING] holidays table' END as status;
echo.
echo -- Leave Management Tables
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'leaves'^) 
echo     THEN '[OK] leaves table exists' 
echo     ELSE '[MISSING] leaves table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'leave_applications'^) 
echo     THEN '[OK] leave_applications table exists' 
echo     ELSE '[MISSING] leave_applications table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'leave_types'^) 
echo     THEN '[OK] leave_types table exists' 
echo     ELSE '[MISSING] leave_types table' END as status;
echo.
echo -- Payroll Tables
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'payslips'^) 
echo     THEN '[OK] payslips table exists' 
echo     ELSE '[MISSING] payslips table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'ps_verifications'^) 
echo     THEN '[OK] ps_verifications table exists' 
echo     ELSE '[MISSING] ps_verifications table' END as status;
echo.
echo -- Code Tables
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'codes'^) 
echo     THEN '[OK] codes table exists' 
echo     ELSE '[MISSING] codes table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'function_codes'^) 
echo     THEN '[OK] function_codes table exists' 
echo     ELSE '[MISSING] function_codes table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'object_codes'^) 
echo     THEN '[OK] object_codes table exists' 
echo     ELSE '[MISSING] object_codes table' END as status;
echo.
echo -- Other Required Tables
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'designations'^) 
echo     THEN '[OK] designations table exists' 
echo     ELSE '[MISSING] designations table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'nationalities'^) 
echo     THEN '[OK] nationalities table exists' 
echo     ELSE '[MISSING] nationalities table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'files'^) 
echo     THEN '[OK] files table exists' 
echo     ELSE '[MISSING] files table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'documents'^) 
echo     THEN '[OK] documents table exists' 
echo     ELSE '[MISSING] documents table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications'^) 
echo     THEN '[OK] notifications table exists' 
echo     ELSE '[MISSING] notifications table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs'^) 
echo     THEN '[OK] audit_logs table exists' 
echo     ELSE '[MISSING] audit_logs table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'settings'^) 
echo     THEN '[OK] settings table exists' 
echo     ELSE '[MISSING] settings table' END as status;
echo.
echo -- Admin Tables
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_dashboard_summary'^) 
echo     THEN '[OK] admin_dashboard_summary table exists' 
echo     ELSE '[MISSING] admin_dashboard_summary table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_actions'^) 
echo     THEN '[OK] admin_actions table exists' 
echo     ELSE '[MISSING] admin_actions table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_settings'^) 
echo     THEN '[OK] admin_settings table exists' 
echo     ELSE '[MISSING] admin_settings table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'system_errors'^) 
echo     THEN '[OK] system_errors table exists' 
echo     ELSE '[MISSING] system_errors table' END as status;
echo.
echo SELECT CASE WHEN EXISTS ^(SELECT 1 FROM information_schema.tables WHERE table_name = 'user_login_history'^) 
echo     THEN '[OK] user_login_history table exists' 
echo     ELSE '[MISSING] user_login_history table' END as status;
echo.
echo -- Summary
echo SELECT '-----------------------------------------' as separator;
echo SELECT COUNT^(*^) || ' total tables in database' as summary FROM information_schema.tables WHERE table_schema = 'public';
echo.
) > temp_verify.sql

echo Running verification...
echo.
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -f temp_verify.sql

del temp_verify.sql

echo.
echo ===========================================
echo VERIFICATION COMPLETE!
echo ===========================================
echo.
echo If you see [MISSING] tables above, run:
echo create-all-missing-tables.bat
echo.
pause