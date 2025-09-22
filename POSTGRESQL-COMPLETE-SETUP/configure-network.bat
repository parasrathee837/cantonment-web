@echo off
color 0E
echo ===========================================================
echo    CONFIGURING NETWORK ACCESS FOR CBA PORTAL
echo ===========================================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if errorlevel 1 (
    echo ERROR: This script must be run as Administrator!
    echo.
    echo Right-click on this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo This will configure Windows Firewall to allow access
echo to your CBA Portal from other computers.
echo.

echo [1/3] Removing old firewall rules...
netsh advfirewall firewall delete rule name="CBA Portal Server" >nul 2>&1
netsh advfirewall firewall delete rule name="Node.js CBA Portal" >nul 2>&1

echo [2/3] Adding firewall rule for port 5000...
netsh advfirewall firewall add rule name="CBA Portal Server" dir=in action=allow protocol=TCP localport=5000 profile=any

echo [3/3] Adding firewall rule for Node.js...
netsh advfirewall firewall add rule name="Node.js CBA Portal" dir=in action=allow program="%ProgramFiles%\nodejs\node.exe" profile=any

echo.
echo ===========================================================
echo    ✓ NETWORK CONFIGURATION COMPLETE!
echo ===========================================================
echo.
echo Your CBA Portal can now be accessed from other computers
echo on your local network.
echo.
echo Make sure all computers are on the same network/WiFi.
echo.
pause