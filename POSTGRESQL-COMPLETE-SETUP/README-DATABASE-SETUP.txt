CBA PORTAL - DATABASE SETUP GUIDE
=================================

CURRENT SITUATION:
- You have PostgreSQL installed and running
- Database 'cba_portal' exists with admin user
- But missing many tables needed for the application

SOLUTION:
Run: apply-schema-windows.bat

This will:
1. Backup your current database
2. Add all missing tables (user_complete_profile, attendance, payslips, etc.)
3. Preserve your admin login
4. Allow the application to save staff data properly

WHAT TABLES WILL BE ADDED:
- user_complete_profile (detailed user information)
- attendance (attendance tracking)
- leaves (leave management)
- payslips (salary slips)
- codes (function/object codes)
- files (document uploads)
- notifications
- audit_logs
- settings

AFTER SETUP:
1. Login to admin portal with your existing admin credentials
2. Create new staff members - all data will be saved properly
3. Use monitoring tools to verify:
   - quick-check-cba.bat (quick overview)
   - monitor-cba-database.bat (detailed monitoring)

TROUBLESHOOTING:
If you get errors:
1. Make sure PostgreSQL service is running
2. Verify password is correct (CBA@2025Portal)
3. Check if database 'cba_portal' exists
4. Run check-database-schema.bat to see current state

FILES IN THIS FOLDER:
- apply-schema-windows.bat (run this to fix database)
- complete-schema.sql (the schema file)
- monitor-cba-database.bat (monitor changes)
- quick-check-cba.bat (quick database check)
- fix-db-connection.bat (if password issues)