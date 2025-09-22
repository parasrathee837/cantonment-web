@echo off
echo ===========================================
echo AUTO MONITORING SETUP
echo ===========================================
echo.

echo This will automatically set up complete monitoring for your CBA Portal:
echo 1. Open pgAdmin4 with automatic connection
echo 2. Start live data monitor  
echo 3. Open your web application
echo.

set /p setup="Start complete auto-monitoring setup? (Y/N): "
if /i not "%setup%"=="Y" exit /b 0

echo.
echo 🔧 Step 1: Setting up pgAdmin4...
call auto-pgadmin-connect.bat

echo.
echo 🔧 Step 2: Starting live monitor...
start "CBA Portal Live Monitor" cmd /k "live-monitor-server-connection.bat"

echo.
echo 🔧 Step 3: Opening web application...
start http://localhost:5000

echo.
echo ✅ COMPLETE SETUP READY!
echo ===========================================
echo.
echo YOU NOW HAVE:
echo 📊 pgAdmin4: Connected to your database
echo 📈 Live Monitor: Real-time data tracking  
echo 🌐 Web App: Ready for testing at localhost:5000
echo.
echo TESTING WORKFLOW:
echo 1. Login to web app: admin / admin123
echo 2. Add staff, mark attendance, etc.
echo 3. Watch live monitor show new records
echo 4. Refresh pgAdmin4 tables (F5) to see same data
echo.
echo MONITORING WINDOWS:
echo - Live Monitor: Shows real-time changes
echo - pgAdmin4: Visual database browser
echo - Web App: Your CBA Portal application  
echo.
echo All three are now synchronized and ready!
echo ===========================================
pause