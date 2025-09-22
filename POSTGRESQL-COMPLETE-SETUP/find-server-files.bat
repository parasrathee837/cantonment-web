@echo off
echo ===========================================
echo Find Server Files and Project Structure
echo ===========================================
echo.

echo Let's search for your server files across the system:
echo.

echo Looking for server files:
echo ========================

echo Searching for server.js files:
dir C:\server.js /s 2>nul | findstr "server.js"

echo.
echo Searching for app.js files:
dir C:\app.js /s 2>nul | findstr "app.js"

echo.
echo Searching for index.js files:
dir C:\index.js /s 2>nul | findstr "index.js"

echo.
echo Looking for package.json files (indicates Node.js projects):
dir C:\package.json /s 2>nul | findstr "package.json"

echo.
echo ALTERNATIVE: Check what's actually running your server
echo =====================================================
echo.

echo Your server is running on port 5000. Let's check what endpoints exist:
echo.

echo Testing basic endpoints:
curl -s http://localhost:5000/ | head -1
echo [Root endpoint test]

echo.
curl -s http://localhost:5000/api | head -1  
echo [API endpoint test]

echo.
echo Let's check what your server console shows:
echo ===========================================
echo.
echo Look at your server console window (where you started the server).
echo It should show something like:
echo - "Server running on port 5000"
echo - Route registrations
echo - File paths being loaded
echo.

echo COMMON CBA PROJECT STRUCTURES:
echo ==============================
echo.
echo Your project might have this structure:
echo.
echo Option 1 - Separate backend folder:
echo ProjectRoot/
echo   ├── backend/
echo   │   ├── server.js
echo   │   ├── routes/
echo   │   └── package.json
echo   └── frontend files
echo.
echo Option 2 - All in root:
echo ProjectRoot/
echo   ├── server.js
echo   ├── routes/
echo   ├── package.json
echo   └── frontend files
echo.
echo Option 3 - Different names:
echo ProjectRoot/
echo   ├── app.js (instead of server.js)
echo   ├── index.js (main entry point)
echo   └── other files
echo.

echo MANUAL SEARCH INSTRUCTIONS:
echo ===========================
echo.
echo 1. Open File Explorer
echo 2. Go to C:\ drive
echo 3. In search box, type: server.js
echo 4. Look for results in folders containing "CBA" or "cantonment"
echo 5. Or search for: package.json
echo 6. Find the one related to your CBA project
echo.

echo Also check these common locations:
echo - Desktop\CBA
echo - Downloads\CBA
echo - Documents\CBA
echo - C:\CBA
echo - C:\Projects\CBA
echo.

pause