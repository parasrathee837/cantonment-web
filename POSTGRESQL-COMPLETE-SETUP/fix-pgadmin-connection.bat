@echo off
echo ===========================================
echo Fix pgAdmin4 Connection to See Tables
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo PROBLEM: You can't see tables in pgAdmin4
echo This means pgAdmin is connected to wrong database/user
echo.

echo Let's verify where your tables actually are:
echo.

echo 1. Checking if tables exist in cba_portal database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Tables in cba_portal: ' || COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"

echo.
echo 2. Checking what databases exist:
psql -h %PGHOST% -p %PGPORT% -d postgres -U %PGUSER% -c "SELECT datname as database_name FROM pg_database WHERE datistemplate = false ORDER BY datname;"

echo.
echo 3. Your server console says it's using:
echo    Username: cba_admin
echo    Database: cba_portal
echo.

echo 4. But we've been using:
echo    Username: postgres
echo    Database: cba_portal
echo.

echo Let's check if cba_admin user exists and has access:
psql -h %PGHOST% -p %PGPORT% -d postgres -U %PGUSER% -c "SELECT usename as username, usesuper as is_superuser FROM pg_user WHERE usename IN ('postgres', 'cba_admin');"

echo.
echo SOLUTION FOR PGADMIN4:
echo ======================
echo.

echo Option 1: Connect pgAdmin4 with these settings:
echo    Host: localhost
echo    Port: 5432
echo    Database: cba_portal
echo    Username: postgres
echo    Password: CBA@2025Portal
echo.

echo Option 2: Create cba_admin user and grant permissions:
set /p create_user="Do you want to create cba_admin user? (Y/N): "
if /i "%create_user%"=="Y" (
    echo.
    echo Creating cba_admin user...
    psql -h %PGHOST% -p %PGPORT% -d postgres -U %PGUSER% -c "CREATE USER cba_admin WITH PASSWORD 'admin123' SUPERUSER;"
    psql -h %PGHOST% -p %PGPORT% -d postgres -U %PGUSER% -c "GRANT ALL PRIVILEGES ON DATABASE cba_portal TO cba_admin;"
    psql -h %PGHOST% -p %PGPORT% -d cba_portal -U %PGUSER% -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO cba_admin;"
    psql -h %PGHOST% -p %PGPORT% -d cba_portal -U %PGUSER% -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO cba_admin;"
    
    echo.
    echo cba_admin user created! Now you can connect pgAdmin4 with:
    echo    Username: cba_admin
    echo    Password: admin123
    echo    Database: cba_portal
)

echo.
echo PGADMIN4 CONNECTION STEPS:
echo ==========================
echo.
echo 1. Open pgAdmin4
echo 2. Right-click "Servers" → "Register" → "Server"
echo 3. General tab:
echo    Name: CBA Portal Local
echo.
echo 4. Connection tab:
echo    Host: localhost
echo    Port: 5432
echo    Maintenance database: cba_portal
echo    Username: postgres  ^(or cba_admin if created^)
echo    Password: CBA@2025Portal  ^(or admin123 for cba_admin^)
echo.
echo 5. Click Save
echo 6. Expand: CBA Portal Local → Databases → cba_portal → Schemas → public → Tables
echo.
echo You should then see all 37 tables!
echo.

echo Verification - List of tables that should appear:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"

echo.
pause