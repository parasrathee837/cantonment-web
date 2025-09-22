# Database Monitoring Guide

This guide explains how to check if data is being updated in your PostgreSQL database.

## Location
All database monitoring tools are located in the `POSTGRESQL-COMPLETE-SETUP` folder.

## Quick Start

### 1. Basic Database Check
Run this for a quick overview:
```batch
cd POSTGRESQL-COMPLETE-SETUP
quick-db-check.bat
```

### 2. Detailed Database Monitor
For interactive monitoring with multiple options:
```batch
cd POSTGRESQL-COMPLETE-SETUP
check-database-updates.bat
```

### 3. Live Monitoring
To continuously monitor changes in real-time:
```batch
cd POSTGRESQL-COMPLETE-SETUP
monitor-live-changes.bat
```

## First Time Setup

If you get password authentication errors:

1. Run `test-postgresql.bat` to check your setup
2. Run `fix-db-connection.bat` to set the correct password

## What Each Tool Does

### quick-db-check.bat
- Shows the 5 most recently modified users
- Displays today's activities (users added, attendance marked)
- Shows recent login activity

### check-database-updates.bat
Interactive menu with options to:
1. Show recent user activities
2. Check total user count
3. View recent logins
4. Check recently added staff
5. View recent attendance records
6. Check payslip generations
7. View all tables with record counts
8. Run custom SQL queries

### monitor-live-changes.bat
- Refreshes every 5 seconds
- Shows changes in the last 60 seconds
- Displays current statistics
- Perfect for testing if your application is updating the database

## Manual Database Checks

You can also check directly using PostgreSQL command line:

1. Open Command Prompt
2. Navigate to PostgreSQL bin directory:
   ```
   cd "C:\Program Files\PostgreSQL\17\bin"
   ```

3. Connect to database:
   ```
   psql -h localhost -U postgres -d cba_portal
   ```

4. Run queries:
   ```sql
   -- Check recent user updates
   SELECT * FROM users ORDER BY updated_at DESC LIMIT 5;
   
   -- Check today's attendance
   SELECT * FROM attendance WHERE DATE(created_at) = CURRENT_DATE;
   
   -- Check login activity
   SELECT username, last_login FROM users 
   WHERE last_login IS NOT NULL 
   ORDER BY last_login DESC LIMIT 5;
   ```

## Troubleshooting

### If no data appears:
1. Ensure PostgreSQL service is running (check with `test-postgresql.bat`)
2. Check if you're connected to the correct database
3. Verify that the application is configured to use PostgreSQL

### To verify application is using PostgreSQL:
1. Check backend/.env file - should have:
   ```
   DB_TYPE=postgresql
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=cba_portal
   DB_USER=postgres
   DB_PASSWORD=your_password
   ```

2. Test the application:
   - Add a new user
   - Run `quick-db-check.bat` to see if it appears
   - Mark attendance
   - Check again to see the update

## Common Queries for Testing

```sql
-- Show tables with row counts
SELECT schemaname,tablename,n_live_tup as row_count 
FROM pg_stat_user_tables 
ORDER BY n_live_tup DESC;

-- Check recent modifications
SELECT * FROM users ORDER BY created_at DESC LIMIT 10;

-- Check if data exists
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM attendance;
SELECT COUNT(*) FROM payslips;
```

## Password Issues

If you get "password authentication failed":
1. Run `fix-db-connection.bat`
2. Enter the password you set during PostgreSQL installation
3. The script will update all monitoring tools with the correct password

Common PostgreSQL passwords:
- `postgres` (default)
- The password you set during installation
- Your Windows admin password