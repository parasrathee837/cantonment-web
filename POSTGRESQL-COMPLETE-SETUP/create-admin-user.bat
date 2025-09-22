@echo off
echo ===========================================
echo Create Admin User - Fix Server Initialization
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo PROBLEM IDENTIFIED: No admin user exists!
echo This is why the server says "Database not initialized"
echo.

echo Creating admin user with credentials shown on your server:
echo Username: admin
echo Password: admin123
echo.

echo Creating admin user...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO users (username, password, role, created_at, updated_at) VALUES ('admin', '\$2b\$12\$YourHashedPasswordHere', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);"

echo.
echo Also creating in user_complete_profile table...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO user_complete_profile (username, password, role, full_name, created_at, updated_at) VALUES ('admin', '\$2b\$12\$YourHashedPasswordHere', 'admin', 'Administrator', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);"

echo.
echo Verifying admin user creation...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT username, role, created_at FROM users WHERE role = 'admin';"

echo.
echo Now check your server console - it should show:
echo ✅ Database initialization complete
echo.
echo You can now login with:
echo Username: admin  
echo Password: admin123
echo.
pause