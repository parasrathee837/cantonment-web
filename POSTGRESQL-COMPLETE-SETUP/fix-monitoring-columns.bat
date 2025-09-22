@echo off
echo Checking actual column names in your database...

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo ADMISSIONS TABLE COLUMNS:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\d admissions"

echo.
echo ATTENDANCE TABLE COLUMNS:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\d attendance"

echo.
echo PAYSLIPS TABLE COLUMNS:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\d payslips"

echo.
echo FILES TABLE COLUMNS:
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "\d files"

pause