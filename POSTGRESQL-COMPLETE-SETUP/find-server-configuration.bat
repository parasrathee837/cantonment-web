@echo off
echo ===========================================
echo FIND SERVER CONFIGURATION ISSUE
echo ===========================================
echo.

echo Your server is running but most API routes return 404.
echo This means the routes are not properly registered in server.js
echo.

echo Let's find your actual server files:
echo ====================================
echo.

echo Searching for server files on C: drive...
echo (This may take a moment)
echo.

for /r C:\ %%i in (server.js) do (
    if exist "%%i" (
        echo Found server.js: %%i
        echo Checking if it contains CBA/cantonment code:
        findstr /i "cantonment\|cba\|admin\|5000" "%%i" >nul 2>&1
        if !errorlevel! equ 0 (
            echo ^^ This looks like your CBA server file
            echo.
        )
    )
)

echo.
echo Searching for package.json files...
for /r C:\ %%i in (package.json) do (
    if exist "%%i" (
        findstr /i "cantonment\|cba" "%%i" >nul 2>&1
        if !errorlevel! equ 0 (
            echo Found CBA package.json: %%i
            echo.
        )
    )
)

echo.
echo ALTERNATIVE: Check running processes
echo ===================================
echo.
echo What's actually running on port 5000:
netstat -ano | findstr :5000
echo.

echo Process details:
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :5000') do (
    tasklist /fi "pid eq %%a" 2>nul | findstr /v "INFO:"
)

echo.
echo QUICK MANUAL CHECK:
echo ==================
echo.
echo 1. Look at your taskbar/desktop for any command prompt windows
echo 2. One of them should be running your server
echo 3. That window should show the actual file path being used
echo 4. Example: "Server running from C:\CBA\cantonment-web\backend\server.js"
echo.
echo 5. Or check your File Explorer Recent files
echo 6. Look for recently opened .js files
echo.

echo NEXT STEPS BASED ON RESULTS:
echo ============================
echo.
echo If you find your server.js file:
echo 1. Open it in notepad
echo 2. Look for lines like: app.use('/api/auth', require('./routes/auth'));
echo 3. Check if these route registrations exist
echo 4. Check if the route files actually exist
echo.
echo This will tell us why only /api/admissions works but others don't!
echo.

pause