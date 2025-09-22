@echo off
color 0A
echo ===========================================================
echo   CREATE SHORTCUTS FOR CLIENT PCs
echo ===========================================================
echo.

:: Get server IP from user
set /p SERVER_IP="Enter your server IP address (e.g., 192.168.1.100): "

if "%SERVER_IP%"=="" (
    echo Error: Please enter the server IP address.
    pause
    exit /b 1
)

echo.
echo Creating shortcuts for: http://%SERVER_IP%:5000
echo.

:: Create desktop shortcut
echo [1/3] Creating desktop shortcut...
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\CBA Portal.lnk'); $Shortcut.TargetPath = 'http://%SERVER_IP%:5000'; $Shortcut.IconLocation = '%SystemRoot%\System32\shell32.dll,13'; $Shortcut.Save()"

:: Create start menu shortcut
echo [2/3] Creating start menu shortcut...
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\CBA Portal" mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\CBA Portal"
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\CBA Portal\CBA Portal.lnk'); $Shortcut.TargetPath = 'http://%SERVER_IP%:5000'; $Shortcut.IconLocation = '%SystemRoot%\System32\shell32.dll,13'; $Shortcut.Save()"

:: Create quick access HTML file
echo [3/3] Creating quick access file...
(
echo ^<!DOCTYPE html^>
echo ^<html^>
echo ^<head^>
echo     ^<title^>CBA Portal Access^</title^>
echo     ^<style^>
echo         body { font-family: Arial; text-align: center; padding: 50px; background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%^); color: white; }
echo         .container { background: rgba(255,255,255,0.1^); padding: 40px; border-radius: 15px; max-width: 500px; margin: 0 auto; }
echo         .btn { display: inline-block; padding: 15px 30px; background: #fff; color: #333; text-decoration: none; border-radius: 8px; font-size: 18px; margin: 10px; }
echo         .btn:hover { background: #f0f0f0; }
echo     ^</style^>
echo ^</head^>
echo ^<body^>
echo     ^<div class="container"^>
echo         ^<h1^>🏛️ CBA Portal Access^</h1^>
echo         ^<p^>Cantonment Board Ambala - Administration System^</p^>
echo         ^<a href="http://%SERVER_IP%:5000" class="btn"^>Open CBA Portal^</a^>
echo         ^<p style="margin-top: 30px; font-size: 14px;"^>
echo             ^<strong^>Default Login:^</strong^>^<br^>
echo             Username: admin^<br^>
echo             Password: admin123
echo         ^</p^>
echo         ^<p style="font-size: 12px; margin-top: 20px;"^>
echo             Server: %SERVER_IP%:5000
echo         ^</p^>
echo     ^</div^>
echo ^</body^>
echo ^</html^>
) > "%USERPROFILE%\Desktop\CBA Portal Access.html"

echo.
echo ===========================================================
echo   ✓ SHORTCUTS CREATED SUCCESSFULLY!
echo ===========================================================
echo.
echo Created:
echo ✓ Desktop shortcut: "CBA Portal"
echo ✓ Start Menu entry
echo ✓ Quick access file: "CBA Portal Access.html"
echo.
echo Users can now:
echo 1. Double-click desktop shortcut
echo 2. Search "CBA Portal" in Start Menu
echo 3. Open the HTML file for quick access
echo.
echo Server address: http://%SERVER_IP%:5000
echo.
pause