@echo off
echo ===========================================
echo CBA Portal - Complete Schema Setup
echo ===========================================
echo.
echo This will create all the missing tables in your database
echo.

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo Current database status:
echo -----------------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT COUNT(*) || ' tables found' FROM information_schema.tables WHERE table_schema = 'public';"
echo.

echo WARNING: This will add the complete CBA Portal schema to your database.
echo Your existing data (admin user) will be preserved.
echo.
set /p confirm="Do you want to continue? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo.
echo Backing up current database...
pg_dump -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f "backup_before_schema_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.sql"

echo.
echo Applying complete schema...
echo.

REM First, let's check which schema file to use
if exist "..\database\postgresql-enhanced-schema-v3.sql" (
    echo Using postgresql-enhanced-schema-v3.sql
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -f ..\database\postgresql-enhanced-schema-v3.sql
) else if exist "..\database\postgresql-enhanced-schema-v2.sql" (
    echo Using postgresql-enhanced-schema-v2.sql
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -f ..\database\postgresql-enhanced-schema-v2.sql
) else if exist "..\database\postgresql-enhanced-schema.sql" (
    echo Using postgresql-enhanced-schema.sql
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -f ..\database\postgresql-enhanced-schema.sql
) else (
    echo ERROR: No schema file found!
    echo Please ensure you have the database folder with schema files.
    pause
    exit /b 1
)

echo.
echo Checking results...
echo.
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT COUNT(*) || ' tables now in database' FROM information_schema.tables WHERE table_schema = 'public';"
echo.
echo New tables created:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"

echo.
echo Schema update complete!
echo.
echo You can now:
echo 1. Login to admin portal
echo 2. Create staff members with full details
echo 3. All data will be properly saved
echo.
pause