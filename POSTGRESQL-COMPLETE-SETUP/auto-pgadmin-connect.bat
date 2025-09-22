@echo off
echo ===========================================
echo Auto-Connect pgAdmin4 to CBA Portal Database
echo ===========================================
echo.

echo This will automatically open pgAdmin4 with the correct connection
echo to your CBA Portal database (same as your running server).
echo.

echo Looking for pgAdmin4 installation...
echo.

REM Try common pgAdmin4 installation paths
set PGADMIN_PATH=""

if exist "C:\Program Files\pgAdmin 4\*\runtime\pgAdmin4.exe" (
    for /d %%i in ("C:\Program Files\pgAdmin 4\*") do (
        if exist "%%i\runtime\pgAdmin4.exe" (
            set PGADMIN_PATH="%%i\runtime\pgAdmin4.exe"
            echo Found pgAdmin4 at: %%i\runtime\pgAdmin4.exe
            goto found
        )
    )
)

if exist "C:\Program Files (x86)\pgAdmin 4\*\runtime\pgAdmin4.exe" (
    for /d %%i in ("C:\Program Files (x86)\pgAdmin 4\*") do (
        if exist "%%i\runtime\pgAdmin4.exe" (
            set PGADMIN_PATH="%%i\runtime\pgAdmin4.exe"
            echo Found pgAdmin4 at: %%i\runtime\pgAdmin4.exe
            goto found
        )
    )
)

REM Try from Start Menu / AppData
if exist "%APPDATA%\pgAdmin 4\pgAdmin4.exe" (
    set PGADMIN_PATH="%APPDATA%\pgAdmin 4\pgAdmin4.exe"
    echo Found pgAdmin4 at: %APPDATA%\pgAdmin 4\pgAdmin4.exe
    goto found
)

REM Try system PATH
pgAdmin4.exe --version >nul 2>&1
if %errorlevel% equ 0 (
    set PGADMIN_PATH=pgAdmin4.exe
    echo Found pgAdmin4 in system PATH
    goto found
)

echo.
echo ❌ pgAdmin4 not found automatically.
echo.
echo MANUAL OPTIONS:
echo 1. Install pgAdmin4 from: https://www.pgadmin.org/download/
echo 2. Or open pgAdmin4 manually and use these settings:
echo    Host: localhost
echo    Port: 5432
echo    Database: cba_portal
echo    Username: postgres
echo    Password: CBA@2025Portal
echo.
pause
exit /b 1

:found
echo.
echo ✅ pgAdmin4 found!
echo.

echo Creating automatic connection configuration...

REM Create pgAdmin4 server configuration
set CONFIG_DIR=%APPDATA%\pgAdmin 4
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

REM Create servers.json for automatic connection
(
echo {
echo   "Servers": {
echo     "1": {
echo       "Name": "CBA Portal Database",
echo       "Group": "Servers",
echo       "Host": "localhost",
echo       "Port": 5432,
echo       "MaintenanceDB": "cba_portal",
echo       "Username": "postgres",
echo       "SSLMode": "prefer",
echo       "Comment": "CBA Portal Database - Auto-configured"
echo     }
echo   }
echo }
) > "%CONFIG_DIR%\servers.json"

echo.
echo 🚀 Launching pgAdmin4 with auto-connection...
echo.

start %PGADMIN_PATH%

echo.
echo ✅ pgAdmin4 should now open with automatic connection!
echo.
echo After pgAdmin4 opens:
echo 1. You should see "CBA Portal Database" in the left panel
echo 2. Click on it to connect (may ask for password: CBA@2025Portal)
echo 3. Navigate to: Databases → cba_portal → Schemas → public → Tables
echo 4. You'll see all your tables!
echo.

echo 📊 Want to monitor live changes?
set /p monitor="Run live monitor alongside pgAdmin4? (Y/N): "
if /i "%monitor%"=="Y" (
    echo.
    echo Starting live monitor...
    start cmd /k "live-monitor-server-connection.bat"
    echo.
    echo Now you have:
    echo ✅ pgAdmin4 open with your database
    echo ✅ Live monitor showing real-time changes
    echo.
    echo Test your web app and watch data sync in real-time!
)

echo.
echo 💡 TIP: When you add data through your web app at http://localhost:5000,
echo        refresh tables in pgAdmin4 (F5) to see the new data!
echo.
pause