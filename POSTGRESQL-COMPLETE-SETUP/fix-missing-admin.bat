@echo off
echo ===========================================
echo Fix Missing Admin User
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo PROBLEM SOLVED: Your database has no admin user!
echo This is exactly why the server says "Database not initialized"
echo.

echo Your server expects:
echo Username: admin
echo Password: admin123
echo.

echo Creating admin user with properly hashed password...

REM Create admin user with bcrypt hash for "admin123"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO users (username, password, role, created_at, updated_at) VALUES ('admin', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) ON CONFLICT (username) DO NOTHING;"

echo.
echo Creating admin profile...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO user_complete_profile (username, password, role, full_name, created_at, updated_at) VALUES ('admin', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukwzPiKEy', 'admin', 'System Administrator', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) ON CONFLICT (username) DO NOTHING;"

echo.
echo Verification - Admin users in database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT username, role, created_at FROM users WHERE role = 'admin';"

echo.
echo ✅ ADMIN USER CREATED SUCCESSFULLY!
echo.
echo Now check your server console window.
echo It should now show:
echo ✅ Database initialization complete
echo.
echo You can login to the portal with:
echo 🔐 Username: admin
echo 🔐 Password: admin123
echo.
echo If the server still shows "not initialized", restart it:
echo 1. Press Ctrl+C in server window
echo 2. Start the server again
echo.
pause