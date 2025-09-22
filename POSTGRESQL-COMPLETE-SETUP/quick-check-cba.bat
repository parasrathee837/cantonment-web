@echo off
REM Quick check for CBA Portal database

set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=cba_portal
set PGUSER=postgres
set PGPASSWORD=CBA@2025Portal

echo ===========================================
echo CBA PORTAL - QUICK DATABASE CHECK
echo ===========================================
echo.

echo DATABASE SUMMARY:
echo -----------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total Users: ' || COUNT(*) FROM users;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total Designations: ' || COUNT(*) FROM designations;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total Nationalities: ' || COUNT(*) FROM nationalities;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total Admissions: ' || COUNT(*) FROM admissions;"
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -t -c "SELECT 'Total PS Verifications: ' || COUNT(*) FROM ps_verifications;"
echo.

echo USERS IN SYSTEM:
echo ----------------
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role, created_at FROM users ORDER BY id;"
echo.

echo ===========================================
pause