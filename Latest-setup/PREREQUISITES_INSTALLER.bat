@echo off
echo ============================================
echo PREREQUISITES AUTOMATIC INSTALLER
echo ============================================
echo.
echo This will download and install:
echo 1. Node.js LTS (if not installed)
echo 2. PostgreSQL 16 (if not installed)
echo 3. Git for Windows (optional)
echo.

echo Checking Windows version...
ver | findstr /i "10\.0\." >nul
if %errorlevel% equ 0 (
    echo ✅ Windows 10 detected
) else (
    ver | findstr /i "11\.0\." >nul
    if %errorlevel% equ 0 (
        echo ✅ Windows 11 detected
    ) else (
        echo ⚠️  Unknown Windows version
    )
)

echo.
echo ============================================
echo CHECKING CURRENT INSTALLATIONS
echo ============================================

echo Checking Node.js...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js NOT installed
    set INSTALL_NODE=1
) else (
    echo ✅ Node.js installed: 
    node --version
    set INSTALL_NODE=0
)

echo.
echo Checking PostgreSQL...
psql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PostgreSQL NOT installed
    set INSTALL_PG=1
) else (
    echo ✅ PostgreSQL installed:
    psql --version
    set INSTALL_PG=0
)

echo.
echo Checking Git...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Git NOT installed (optional)
    set INSTALL_GIT=1
) else (
    echo ✅ Git installed:
    git --version
    set INSTALL_GIT=0
)

echo.
echo ============================================
echo DOWNLOAD LINKS
echo ============================================

if %INSTALL_NODE% equ 1 (
    echo.
    echo NODE.JS INSTALLATION REQUIRED:
    echo ==============================
    echo 1. Download from: https://nodejs.org/en/download/
    echo 2. Choose "Windows Installer (.msi)" - 64-bit
    echo 3. Download LTS version (20.x)
    echo 4. Run installer with default settings
    echo 5. Restart this script after installation
    echo.
    echo Opening Node.js download page...
    start https://nodejs.org/en/download/
)

if %INSTALL_PG% equ 1 (
    echo.
    echo POSTGRESQL INSTALLATION REQUIRED:
    echo =================================
    echo 1. Download from: https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
    echo 2. Choose PostgreSQL 16 for Windows x86-64
    echo 3. Run installer with these settings:
    echo    - Installation Directory: Default
    echo    - Password: Set a strong password (remember it!)
    echo    - Port: 5432 (default)
    echo    - Locale: Default
    echo    - DO NOT launch Stack Builder at end
    echo 4. Restart this script after installation
    echo.
    echo Opening PostgreSQL download page...
    start https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
)

if %INSTALL_GIT% equ 1 (
    echo.
    echo GIT INSTALLATION (OPTIONAL):
    echo ============================
    echo 1. Download from: https://git-scm.com/download/win
    echo 2. Choose 64-bit Git for Windows Setup
    echo 3. Run installer with default settings
    echo.
    set /p installgit="Install Git? (Y/N): "
    if /i "%installgit%"=="Y" (
        echo Opening Git download page...
        start https://git-scm.com/download/win
    )
)

if %INSTALL_NODE% equ 0 if %INSTALL_PG% equ 0 (
    echo.
    echo ============================================
    echo ✅ ALL PREREQUISITES INSTALLED!
    echo ============================================
    echo.
    echo You can now run INSTALL_EVERYTHING.bat
    echo.
) else (
    echo.
    echo ============================================
    echo ACTION REQUIRED
    echo ============================================
    echo.
    echo 1. Install the missing prerequisites above
    echo 2. Restart your computer (recommended)
    echo 3. Run this script again to verify
    echo 4. Then run INSTALL_EVERYTHING.bat
    echo.
)

echo.
echo ============================================
echo ADDITIONAL TOOLS (OPTIONAL)
echo ============================================
echo.
echo For better development experience, consider:
echo.
echo 1. Visual Studio Code
echo    https://code.visualstudio.com/
echo.
echo 2. pgAdmin 4 (PostgreSQL GUI)
echo    https://www.pgadmin.org/download/
echo.
echo 3. Postman (API Testing)
echo    https://www.postman.com/downloads/
echo.

pause