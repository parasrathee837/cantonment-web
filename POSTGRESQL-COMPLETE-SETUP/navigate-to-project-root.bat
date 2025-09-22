@echo off
echo ===========================================
echo Navigate to Project Root Directory
echo ===========================================
echo.

echo Current directory: %cd%
echo You're in the POSTGRESQL-COMPLETE-SETUP folder, but need to be in project root.
echo.

echo Let's find your project root directory:
echo.

echo Looking for project root...
if exist "..\backend" (
    echo Found backend directory one level up!
    echo Project root is: 
    cd ..
    echo %cd%
    cd POSTGRESQL-COMPLETE-SETUP
) else if exist "..\..\backend" (
    echo Found backend directory two levels up!
    echo Project root is:
    cd ..\..
    echo %cd%
    cd POSTGRESQL-COMPLETE-SETUP
) else if exist "..\..\..\backend" (
    echo Found backend directory three levels up!
    echo Project root is:
    cd ..\..\..
    echo %cd%
    cd POSTGRESQL-COMPLETE-SETUP
) else (
    echo Backend directory not found in nearby locations.
    echo.
    echo Please manually navigate to your project root where you have:
    echo - backend/ folder
    echo - fixed-frontend.html
    echo - Other project files
    echo.
    echo Possible locations:
    echo - C:\CBA\cantonment-web\
    echo - C:\CBA\
    echo - Your Downloads folder
    echo - Desktop
)

echo.
echo MANUAL NAVIGATION:
echo =================
echo.
echo 1. Open File Explorer
echo 2. Navigate to where you have your CBA project files
echo 3. Look for the folder containing 'backend' and 'fixed-frontend.html'
echo 4. Open Command Prompt in that folder (Shift+Right-click → "Open PowerShell/Command Prompt here")
echo 5. Then run: cd POSTGRESQL-COMPLETE-SETUP
echo 6. Then run: check-actual-routes.bat
echo.

echo QUICK SEARCH:
echo =============
echo.
set /p search="Search for backend folder on C: drive? (Y/N): "
if /i "%search%"=="Y" (
    echo Searching for backend folders...
    dir C:\backend /s /ad 2>nul | findstr "backend"
    echo.
    echo Look for a backend folder that contains:
    echo - routes folder
    echo - server.js file
    echo - package.json file
)

echo.
echo Once you find your project root, run this from there:
echo POSTGRESQL-COMPLETE-SETUP\check-actual-routes.bat
echo.
pause