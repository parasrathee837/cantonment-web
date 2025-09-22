# Troubleshooting JSON Parse Errors

## Error You're Seeing:
```
Delete error: SyntaxError: JSON.parse: unexpected character at line 1 column 1 of the JSON data localhost:5000:15218:33
```

## What This Means:
Your frontend is expecting JSON data from the backend, but it's receiving something else (likely an HTML error page or plain text).

## Common Causes:

### 1. **Missing Database Tables** (Most Likely)
When the backend tries to query a table that doesn't exist, it crashes and returns an HTML error page instead of JSON.

**Tables that commonly cause this:**
- `user_complete_profile` 
- `attendance`
- `payslips` 
- `files`
- `staff_personal`

### 2. **Backend Server Issues**
- Server crashed or not running
- Database connection failed
- Missing npm packages
- Configuration errors

### 3. **Database Query Errors**
- Wrong column names
- Missing foreign key relationships
- SQL syntax errors

## How to Fix:

### Step 1: Check Database
```batch
fix-backend-errors.bat
```
This will check your database and identify missing tables.

### Step 2: Fix Missing Tables
```batch
create-all-missing-tables.bat
```
This creates all the tables your application needs.

### Step 3: Debug API Responses
```batch
debug-json-error.bat
```
This tests your API endpoints to see what they're actually returning.

### Step 4: Check Backend Console
Look at your backend server console for error messages like:
- `relation "user_complete_profile" does not exist`
- `column "staff_name" does not exist`
- `connection refused`

## Manual Debugging:

### Test API Endpoints Manually:
```bash
# Test if backend is running
curl http://localhost:5000/api/health

# Test specific endpoints
curl http://localhost:5000/api/users
curl http://localhost:5000/api/admissions
```

### Check What's Being Returned:
If you see HTML instead of JSON, that's your problem. The backend is returning an error page.

## Most Likely Solution:

Your JSON error is probably caused by **missing database tables**. 

**Quick Fix:**
1. Run `create-all-missing-tables.bat`
2. Restart your backend server
3. Try the operation again

This should resolve the JSON parsing errors by ensuring all required database tables exist.

## Prevention:

After fixing, use the monitoring tools to ensure data is being saved correctly:
- `watch-database-live-safe.bat` - Monitor database changes
- `verify-all-tables.bat` - Check all tables exist

## If Still Having Issues:

1. Check backend `.env` file has correct database settings
2. Ensure PostgreSQL is running
3. Verify all npm packages are installed (`npm install`)
4. Check backend logs for specific error messages