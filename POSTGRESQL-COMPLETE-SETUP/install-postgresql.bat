@echo off
color 0B
echo ===========================================================
echo    AUTOMATIC POSTGRESQL INSTALLER FOR CBA PORTAL
echo ===========================================================
echo.
echo This will download and install PostgreSQL automatically.
echo.
echo IMPORTANT NOTES:
echo - Installation takes 10-15 minutes
echo - You will be asked to set a password
echo - REMEMBER THIS PASSWORD!
echo - Suggested password: CBA@2025Portal
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

:: Create temp directory
if not exist "%temp%\cba-postgresql" mkdir "%temp%\cba-postgresql"

:: Download PostgreSQL installer
echo [1/3] Downloading PostgreSQL 15...
echo This is a large file (200+ MB), please be patient...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://get.enterprisedb.com/postgresql/postgresql-15.4-1-windows-x64.exe' -OutFile '%temp%\cba-postgresql\postgresql.exe'}"

if not exist "%temp%\cba-postgresql\postgresql.exe" (
    echo.
    echo ERROR: Download failed!
    echo.
    echo Please download manually from:
    echo https://www.postgresql.org/download/windows/
    echo.
    echo Look for "Download the installer" section
    echo Choose PostgreSQL 15 or 16 for Windows x86-64
    echo.
    pause
    exit /b 1
)

echo [2/3] Installing PostgreSQL...
echo.
echo ⚠️  IMPORTANT: When asked for password, use: CBA@2025Portal
echo    (or your own password, but REMEMBER IT!)
echo.
echo The installer will open now. Follow these steps:
echo 1. Click Next → Next → Next
echo 2. When asked for password, enter: CBA@2025Portal
echo 3. Port: 5432 (keep default)
echo 4. Locale: Default
echo 5. Complete installation
echo.
pause

:: Run installer
"%temp%\cba-postgresql\postgresql.exe"

echo [3/3] Verifying installation...
timeout /t 10 /nobreak >nul

:: Check if PostgreSQL is installed
psql --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo WARNING: PostgreSQL command not found in PATH.
    echo This might be normal. Checking service...
    
    :: Check if service exists
    sc query postgresql-x64-15 >nul 2>&1
    if errorlevel 1 (
        sc query postgresql-x64-16 >nul 2>&1
        if errorlevel 1 (
            echo.
            echo ⚠️  PostgreSQL installation may have failed.
            echo    Please check if PostgreSQL installed correctly.
            echo    Look for PostgreSQL in Start Menu.
        ) else (
            echo ✓ PostgreSQL 16 service found
        )
    ) else (
        echo ✓ PostgreSQL 15 service found
    )
) else (
    echo.
    echo ===========================================================
    echo    ✓ POSTGRESQL INSTALLED SUCCESSFULLY!
    echo ===========================================================
    echo.
    for /f "tokens=*" %%i in ('psql --version') do echo Installed: %%i
    echo.
    echo Service status:
    sc query postgresql-x64-15 2>nul | find "STATE" || sc query postgresql-x64-16 2>nul | find "STATE" || echo Service check failed
)

:: Cleanup
rd /s /q "%temp%\cba-postgresql" 2>nul

echo.
echo ===========================================================
echo   INSTALLATION COMPLETED
echo ===========================================================
echo.
echo REMEMBER YOUR PASSWORD: CBA@2025Portal (or what you set)
echo.
echo Next step: Continue with STEP-2-Copy-Project-Files.txt
echo.
pause