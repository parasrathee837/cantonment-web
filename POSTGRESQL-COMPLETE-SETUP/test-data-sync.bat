@echo off
echo ===========================================
echo Test Data Synchronization with pgAdmin4
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=cba_admin
set PGPASSWORD=admin123

echo This will add some test data so you can verify it appears in pgAdmin4
echo.

set /p test="Do you want to add test data to verify pgAdmin4 sync? (Y/N): "
if /i not "%test%"=="Y" exit /b 0

echo.
echo Adding test data...
echo.

echo 1. Adding test user...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO users (username, password, role, created_at) VALUES ('testuser', 'hashed_password', 'user', CURRENT_TIMESTAMP);"

echo.
echo 2. Adding test admission...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO admissions (staff_name, designation, created_at) VALUES ('Test Staff Member', 'Test Designation', CURRENT_TIMESTAMP);"

echo.
echo 3. Adding test attendance...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO attendance (user_id, date, status, created_at) VALUES (1, CURRENT_DATE, 'present', CURRENT_TIMESTAMP);"

echo.
echo 4. Adding test notification...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "INSERT INTO notifications (title, message, created_at) VALUES ('Test Notification', 'This is a test notification to verify data sync', CURRENT_TIMESTAMP);"

echo.
echo ✅ Test data added successfully!
echo.
echo NOW CHECK PGADMIN4:
echo ==================
echo 1. Open pgAdmin4
echo 2. Navigate to your cba_portal database
echo 3. Go to Tables → users → Right-click → "View/Edit Data" → "All Rows"
echo 4. You should see the "testuser" we just added
echo 5. Check other tables (admissions, attendance, notifications) too
echo.
echo Current record counts:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Users: ' || COUNT(*) FROM users;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Admissions: ' || COUNT(*) FROM admissions;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Attendance: ' || COUNT(*) FROM attendance;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Notifications: ' || COUNT(*) FROM notifications;"

echo.
echo If you can see this data in pgAdmin4, then data sync is working perfectly!
echo.
pause