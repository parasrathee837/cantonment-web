@echo off
color 0D
echo ===========================================================
echo   POSTGRESQL DATABASE RESTORE TOOL
echo ===========================================================
echo.

:: Check if backup directory exists
if not exist "C:\CBA_Portal\cantonment-web\backups" (
    echo ❌ Backups directory not found!
    echo.
    echo Please make sure you have backup files in:
    echo C:\CBA_Portal\cantonment-web\backups\
    echo.
    pause
    exit /b 1
)

:: List available backups
echo Available backup files:
echo ----------------------
dir "C:\CBA_Portal\cantonment-web\backups\*.sql" /b /o-d 2>nul
if errorlevel 1 (
    echo No backup files found!
    echo.
    echo Please create a backup first using backup-database.bat
    echo.
    pause
    exit /b 1
)

echo.
echo WARNING: This will REPLACE all current data in the database!
echo Make sure you have a current backup before proceeding.
echo.
set /p CONTINUE="Are you sure you want to restore? (y/N): "

if /i not "%CONTINUE%"=="y" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo.
set /p BACKUP_FILE="Enter the backup filename (from list above): "

if "%BACKUP_FILE%"=="" (
    echo Error: No filename specified.
    pause
    exit /b 1
)

set FULL_PATH=C:\CBA_Portal\cantonment-web\backups\%BACKUP_FILE%

if not exist "%FULL_PATH%" (
    echo Error: Backup file not found: %FULL_PATH%
    pause
    exit /b 1
)

:: Set password for database connection
set PGPASSWORD=CBA@2025Portal

echo.
echo Restoring database from: %BACKUP_FILE%
echo.

echo [1/3] Stopping any running CBA Portal servers...
echo Please close any running "start-cba-portal-postgresql.bat" windows now.
echo.
pause

echo [2/3] Clearing current database...
echo DROP SCHEMA public CASCADE; CREATE SCHEMA public; | psql -U cba_admin -d cba_portal -h localhost

echo [3/3] Restoring from backup...
psql -U cba_admin -d cba_portal -h localhost -f "%FULL_PATH%"

if errorlevel 1 (
    echo.
    echo ❌ RESTORE FAILED!
    echo.
    echo Possible issues:
    echo 1. PostgreSQL service not running
    echo 2. Database credentials incorrect
    echo 3. Backup file corrupted
    echo 4. CBA Portal server still running
    echo.
    pause
    exit /b 1
)

echo.
echo ===========================================================
echo   ✓ RESTORE COMPLETED SUCCESSFULLY!
echo ===========================================================
echo.
echo Database restored from: %BACKUP_FILE%
echo.
echo You can now start the CBA Portal server:
echo start-cba-portal-postgresql.bat
echo.
echo IMPORTANT: All previous data has been replaced!
echo.
pause