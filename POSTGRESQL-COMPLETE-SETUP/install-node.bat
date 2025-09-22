@echo off
color 0A
echo ===========================================================
echo    AUTOMATIC NODE.JS INSTALLER FOR CBA PORTAL
echo ===========================================================
echo.
echo This will download and install Node.js automatically.
echo Please wait...
echo.

:: Create temp directory
if not exist "%temp%\cba-install" mkdir "%temp%\cba-install"

:: Download Node.js installer
echo [1/3] Downloading Node.js...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://nodejs.org/dist/v18.17.1/node-v18.17.1-x64.msi' -OutFile '%temp%\cba-install\nodejs.msi'}"

if not exist "%temp%\cba-install\nodejs.msi" (
    echo.
    echo ERROR: Download failed!
    echo Please download manually from https://nodejs.org
    echo.
    pause
    exit /b 1
)

echo [2/3] Installing Node.js...
echo This may take a few minutes...
msiexec /i "%temp%\cba-install\nodejs.msi" /quiet /norestart

echo [3/3] Verifying installation...
timeout /t 5 /nobreak >nul

:: Verify installation
node --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo WARNING: Node.js may require a system restart.
    echo Please restart your computer and try again.
) else (
    echo.
    echo ===========================================================
    echo    ✓ NODE.JS INSTALLED SUCCESSFULLY!
    echo ===========================================================
    echo.
    for /f "tokens=*" %%i in ('node --version') do echo Installed version: %%i
)

:: Cleanup
rd /s /q "%temp%\cba-install" 2>nul

echo.
pause