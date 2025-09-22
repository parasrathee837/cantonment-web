@echo off
echo ===========================================
echo Quick Fix - Add Missing Tables Only
echo ===========================================
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo This will add only the essential missing tables without affecting existing data.
echo.

echo Creating missing tables...
echo.

REM Create the SQL commands to add missing tables
echo -- Adding missing essential tables > temp_missing_tables.sql

echo. >> temp_missing_tables.sql
echo -- Extended user information >> temp_missing_tables.sql
echo CREATE TABLE IF NOT EXISTS user_complete_profile ( >> temp_missing_tables.sql
echo     id SERIAL PRIMARY KEY, >> temp_missing_tables.sql
echo     username VARCHAR(100) UNIQUE NOT NULL, >> temp_missing_tables.sql
echo     password VARCHAR(255) NOT NULL, >> temp_missing_tables.sql
echo     full_name VARCHAR(100), >> temp_missing_tables.sql
echo     email VARCHAR(100), >> temp_missing_tables.sql
echo     mobile VARCHAR(15), >> temp_missing_tables.sql
echo     role VARCHAR(20) DEFAULT 'user', >> temp_missing_tables.sql
echo     designation VARCHAR(100), >> temp_missing_tables.sql
echo     department VARCHAR(100), >> temp_missing_tables.sql
echo     address TEXT, >> temp_missing_tables.sql
echo     profile_photo VARCHAR(255), >> temp_missing_tables.sql
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, >> temp_missing_tables.sql
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, >> temp_missing_tables.sql
echo     last_login TIMESTAMP >> temp_missing_tables.sql
echo ); >> temp_missing_tables.sql

echo. >> temp_missing_tables.sql
echo -- Attendance table >> temp_missing_tables.sql
echo CREATE TABLE IF NOT EXISTS attendance ( >> temp_missing_tables.sql
echo     id SERIAL PRIMARY KEY, >> temp_missing_tables.sql
echo     user_id INTEGER REFERENCES users(id), >> temp_missing_tables.sql
echo     date DATE NOT NULL, >> temp_missing_tables.sql
echo     status VARCHAR(20) NOT NULL, >> temp_missing_tables.sql
echo     check_in_time TIME, >> temp_missing_tables.sql
echo     check_out_time TIME, >> temp_missing_tables.sql
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP >> temp_missing_tables.sql
echo ); >> temp_missing_tables.sql

echo. >> temp_missing_tables.sql
echo -- Leaves table >> temp_missing_tables.sql
echo CREATE TABLE IF NOT EXISTS leaves ( >> temp_missing_tables.sql
echo     id SERIAL PRIMARY KEY, >> temp_missing_tables.sql
echo     user_id INTEGER REFERENCES users(id), >> temp_missing_tables.sql
echo     leave_type VARCHAR(50), >> temp_missing_tables.sql
echo     start_date DATE NOT NULL, >> temp_missing_tables.sql
echo     end_date DATE NOT NULL, >> temp_missing_tables.sql
echo     reason TEXT, >> temp_missing_tables.sql
echo     status VARCHAR(20) DEFAULT 'pending', >> temp_missing_tables.sql
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP >> temp_missing_tables.sql
echo ); >> temp_missing_tables.sql

echo. >> temp_missing_tables.sql
echo -- Payslips table >> temp_missing_tables.sql
echo CREATE TABLE IF NOT EXISTS payslips ( >> temp_missing_tables.sql
echo     id SERIAL PRIMARY KEY, >> temp_missing_tables.sql
echo     user_id INTEGER REFERENCES users(id), >> temp_missing_tables.sql
echo     month INTEGER NOT NULL, >> temp_missing_tables.sql
echo     year INTEGER NOT NULL, >> temp_missing_tables.sql
echo     basic_salary DECIMAL(10,2), >> temp_missing_tables.sql
echo     allowances DECIMAL(10,2), >> temp_missing_tables.sql
echo     deductions DECIMAL(10,2), >> temp_missing_tables.sql
echo     net_salary DECIMAL(10,2), >> temp_missing_tables.sql
echo     generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP >> temp_missing_tables.sql
echo ); >> temp_missing_tables.sql

echo. >> temp_missing_tables.sql
echo -- Codes table >> temp_missing_tables.sql
echo CREATE TABLE IF NOT EXISTS codes ( >> temp_missing_tables.sql
echo     id SERIAL PRIMARY KEY, >> temp_missing_tables.sql
echo     code_type VARCHAR(50) NOT NULL, >> temp_missing_tables.sql
echo     code VARCHAR(20) NOT NULL, >> temp_missing_tables.sql
echo     description VARCHAR(255), >> temp_missing_tables.sql
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP >> temp_missing_tables.sql
echo ); >> temp_missing_tables.sql

echo. >> temp_missing_tables.sql
echo -- Files table >> temp_missing_tables.sql
echo CREATE TABLE IF NOT EXISTS files ( >> temp_missing_tables.sql
echo     id SERIAL PRIMARY KEY, >> temp_missing_tables.sql
echo     user_id INTEGER REFERENCES users(id), >> temp_missing_tables.sql
echo     filename VARCHAR(255) NOT NULL, >> temp_missing_tables.sql
echo     filepath VARCHAR(500) NOT NULL, >> temp_missing_tables.sql
echo     file_type VARCHAR(50), >> temp_missing_tables.sql
echo     uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP >> temp_missing_tables.sql
echo ); >> temp_missing_tables.sql

echo. >> temp_missing_tables.sql
echo -- Sync existing users to user_complete_profile >> temp_missing_tables.sql
echo INSERT INTO user_complete_profile (username, password, role, created_at, updated_at) >> temp_missing_tables.sql
echo SELECT username, password, role, created_at, updated_at FROM users >> temp_missing_tables.sql
echo ON CONFLICT (username) DO NOTHING; >> temp_missing_tables.sql

echo Applying missing tables...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -f temp_missing_tables.sql

del temp_missing_tables.sql

echo.
echo Checking results...
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"

echo.
echo Missing tables have been added!
echo The application should now work properly.
echo.
pause