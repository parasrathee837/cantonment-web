@echo off
echo ===========================================
echo pgAdmin4 Connection Guide - Server Match
echo ===========================================
echo.

echo Your server is running and connected to PostgreSQL.
echo To see the SAME data in pgAdmin4, use these EXACT settings:
echo.

echo SERVER CONNECTION DETAILS:
echo ==========================
echo.
echo 🔧 Connection Name: CBA Portal Server
echo 🏠 Host: localhost
echo 🔌 Port: 5432  
echo 🗄️ Database: cba_portal
echo 👤 Username: postgres
echo 🔐 Password: CBA@2025Portal
echo.

echo STEP-BY-STEP PGADMIN4 SETUP:
echo ============================
echo.
echo 1. Open pgAdmin4
echo 2. Right-click "Servers" in left panel
echo 3. Select "Register" → "Server..."
echo 4. In "General" tab:
echo    - Name: CBA Portal Server
echo 5. In "Connection" tab:
echo    - Host name/address: localhost
echo    - Port: 5432
echo    - Maintenance database: cba_portal
echo    - Username: postgres  
echo    - Password: CBA@2025Portal
echo 6. Click "Save"
echo.

echo VERIFY CONNECTION:
echo =================
echo.
echo After connecting, navigate to:
echo Servers → CBA Portal Server → Databases → cba_portal → Schemas → public → Tables
echo.
echo You should see ALL these tables:
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Tables in your database:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"

echo.
echo QUICK TEST:
echo ==========
echo.
echo Current record counts (should match pgAdmin4):
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Users: ' || COUNT(*) FROM users;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Admissions: ' || COUNT(*) FROM admissions;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Designations: ' || COUNT(*) FROM designations;"

echo.
echo 💡 If you can't see tables in pgAdmin4:
echo 1. Make sure you're using the EXACT credentials above
echo 2. Check you selected the "cba_portal" database (not "postgres")
echo 3. Expand the tree: Databases → cba_portal → Schemas → public → Tables
echo 4. If still no tables, the connection might be to wrong database
echo.

echo 🚀 Once connected, run this monitor:
echo live-monitor-server-connection.bat
echo.
echo It will show real-time updates that you can verify in pgAdmin4!
echo.
pause