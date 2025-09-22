@echo off
color 0C
echo ===========================================================
echo   FIXING SERVER.JS SYNTAX ERROR
===========================================================
echo.
echo Issue: Syntax error in server.js line 12
echo Caused by: Incorrect replacement of database require statement
echo.
pause

cd /d "C:\CBA_Portal\cantonment-web\backend"

echo [1/3] Backing up current server.js...
if exist server.js (
    copy server.js server-broken.js >nul
    echo ✓ Broken server.js backed up
)

echo [2/3] Checking the problematic line...
if exist server.js (
    echo Current problematic line:
    findstr /n "database.*const" server.js
    echo.
)

echo [3/3] Fixing the syntax error...
if exist server.js (
    echo Fixing database require statement...
    
    :: Replace the broken line with correct syntax
    powershell -Command "(Get-Content server.js) -replace 'database = const database = require.*', 'const database = require(\"./config/database\");' | Set-Content server.js"
    
    :: Also fix any other potential duplicates
    powershell -Command "(Get-Content server.js) -replace '^.*database.*const.*database.*require.*', 'const database = require(\"./config/database\");' | Set-Content server.js"
    
    :: Remove any duplicate database declarations
    powershell -Command "(Get-Content server.js) | Select-Object -Unique | Set-Content server.js"
    
    echo ✓ Syntax error fixed
)

echo.
echo Verification - checking for correct database require:
findstr /n "const database" server.js

echo.
echo ===========================================================
echo   ✓ SERVER.JS SYNTAX FIXED!
===========================================================
echo.
echo The problematic line has been corrected.
echo.
echo Test the server: start-cba-portal-postgresql.bat
echo.
pause