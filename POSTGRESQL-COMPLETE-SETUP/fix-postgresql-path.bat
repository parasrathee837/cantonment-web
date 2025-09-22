@echo off
color 0C
echo ===========================================================
echo   FIXING POSTGRESQL PATH ISSUE
===========================================================
echo.

echo Checking for PostgreSQL installation...
echo.

:: Check common PostgreSQL installation paths
set PGPATH=
if exist "C:\Program Files\PostgreSQL\15\bin\psql.exe" (
    set PGPATH=C:\Program Files\PostgreSQL\15\bin
    echo ✓ Found PostgreSQL 15 at: %PGPATH%
    goto :found
)

if exist "C:\Program Files\PostgreSQL\16\bin\psql.exe" (
    set PGPATH=C:\Program Files\PostgreSQL\16\bin
    echo ✓ Found PostgreSQL 16 at: %PGPATH%
    goto :found
)

if exist "C:\Program Files\PostgreSQL\14\bin\psql.exe" (
    set PGPATH=C:\Program Files\PostgreSQL\14\bin
    echo ✓ Found PostgreSQL 14 at: %PGPATH%
    goto :found
)

if exist "C:\Program Files\PostgreSQL\17\bin\psql.exe" (
    set PGPATH=C:\Program Files\PostgreSQL\17\bin
    echo ✓ Found PostgreSQL 17 at: %PGPATH%
    goto :found
)

echo ❌ PostgreSQL not found in standard locations!
echo.
echo SOLUTION 1: Install PostgreSQL
echo - Run install-postgresql.bat
echo - Or download from: https://www.postgresql.org/download/windows/
echo.
echo SOLUTION 2: Manual PATH fix (if already installed)
echo - Find your PostgreSQL installation folder
echo - Add the \bin folder to Windows PATH
echo.
pause
exit /b 1

:found
echo.
echo [1/2] Adding PostgreSQL to PATH...
setx PATH "%PATH%;%PGPATH%" /M >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Could not set system PATH (need admin rights)
    echo Trying user PATH instead...
    setx PATH "%PATH%;%PGPATH%" >nul 2>&1
)

echo [2/2] Testing PostgreSQL access...
"%PGPATH%\psql.exe" --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Still cannot access PostgreSQL
) else (
    echo ✓ PostgreSQL now accessible!
)

echo.
echo ===========================================================
echo   PATH FIX COMPLETE
===========================================================
echo.
echo PostgreSQL found at: %PGPATH%
echo.
echo IMPORTANT: You may need to:
echo 1. Close this window
echo 2. Close any other command windows
echo 3. Try your setup again
echo.
echo Or restart your computer for PATH changes to take effect.
echo.
pause