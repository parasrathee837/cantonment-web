@echo off
color 0E
echo ===========================================================
echo   POSTGRESQL DATABASE BACKUP TOOL
echo ===========================================================
echo.

:: Create backups directory if it doesn't exist
if not exist "C:\CBA_Portal\cantonment-web\backups" mkdir "C:\CBA_Portal\cantonment-web\backups"

:: Set password for database connection
set PGPASSWORD=CBA@2025Portal

:: Generate timestamp for backup filename
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set timestamp=%datetime:~0,4%%datetime:~4,2%%datetime:~6,2%_%datetime:~8,2%%datetime:~10,2%%datetime:~12,2%

:: Set backup filename
set BACKUP_FILE=C:\CBA_Portal\cantonment-web\backups\cba_portal_backup_%timestamp%.sql

echo Creating PostgreSQL backup...
echo.
echo Backup details:
echo ---------------
echo Database: cba_portal
echo Server: localhost:5432
echo User: cba_admin
echo File: %BACKUP_FILE%
echo.

echo [1/2] Creating database backup...
pg_dump -U cba_admin -h localhost -p 5432 -d cba_portal -f "%BACKUP_FILE%" -v

if errorlevel 1 (
    echo.
    echo ❌ BACKUP FAILED!
    echo.
    echo Possible issues:
    echo 1. PostgreSQL service not running
    echo 2. Database credentials incorrect
    echo 3. pg_dump not in PATH
    echo.
    echo Troubleshooting:
    echo - Check if PostgreSQL service is running
    echo - Verify database connection in pgAdmin
    echo - Make sure pg_dump is installed with PostgreSQL
    echo.
    pause
    exit /b 1
)

echo [2/2] Verifying backup...
if exist "%BACKUP_FILE%" (
    for %%A in ("%BACKUP_FILE%") do set size=%%~zA
    if %size% GTR 1000 (
        echo.
        echo ===========================================================
        echo   ✓ BACKUP COMPLETED SUCCESSFULLY!
        echo ===========================================================
        echo.
        echo Backup saved to: %BACKUP_FILE%
        echo File size: %size% bytes
        echo Timestamp: %timestamp%
        echo.
        
        :: List recent backups
        echo Recent backups:
        echo ---------------
        dir "C:\CBA_Portal\cantonment-web\backups\*.sql" /b /o-d 2>nul | head -5
        
    ) else (
        echo ⚠️  Backup file is very small (%size% bytes)
        echo This might indicate an incomplete backup.
    )
) else (
    echo ❌ Backup file not created!
)

echo.
echo ===========================================================
echo   BACKUP INFORMATION
echo ===========================================================
echo.
echo To restore this backup:
echo 1. Stop the CBA Portal server
echo 2. Use: restore-database.bat
echo 3. Or manually: psql -U cba_admin -d cba_portal -f backup_file.sql
echo.
echo Backup location: C:\CBA_Portal\cantonment-web\backups\
echo.
echo Recommended: Create backups daily or weekly
echo.
pause