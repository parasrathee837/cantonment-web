@echo off
echo ===========================================
echo Check What User Route Files Actually Exist
echo ===========================================
echo.

echo Let's check what route files you actually have in your backend:
echo.

echo Checking backend/routes/ directory:
if exist "..\backend\routes" (
    echo.
    echo Files in backend/routes/:
    dir "..\backend\routes\*.js" /b
    echo.
    
    echo User-related route files:
    dir "..\backend\routes\user*.js" /b 2>nul
    if %errorlevel% neq 0 echo No user*.js files found
    
    echo.
    echo Let's see what endpoints your actual route files provide:
    echo.
    
    if exist "..\backend\routes\users.js" (
        echo Found users.js - checking its contents...
        echo First 20 lines:
        type "..\backend\routes\users.js" | more +1 | head -20
    )
    
    if exist "..\backend\routes\users-enhanced.js" (
        echo Found users-enhanced.js - checking its contents...
        echo First 20 lines:
        type "..\backend\routes\users-enhanced.js" | more +1 | head -20
    )
    
    if exist "..\backend\routes\auth.js" (
        echo Found auth.js - might handle user creation...
        echo Checking for POST routes:
        findstr /i "post\|create\|register" "..\backend\routes\auth.js"
    )
    
) else (
    echo ERROR: backend/routes directory not found!
    echo Current directory:
    cd
    echo.
    echo Please navigate to your project root directory first.
)

echo.
echo SOLUTION APPROACHES:
echo ===================
echo.
echo Option 1: Use existing working routes
echo - Find which route file actually handles user operations
echo - Update frontend to use the correct endpoints
echo.
echo Option 2: Create the missing users-normalized.js file
echo - Copy from users.js and modify for normalized operations
echo.
echo Option 3: Check server.js for route registration
echo - See which routes are actually loaded by the server
echo.

set /p check_server="Check server.js for route registration? (Y/N): "
if /i "%check_server%"=="Y" (
    if exist "..\backend\server.js" (
        echo.
        echo Checking server.js for route registrations:
        findstr /i "route\|app.use\|users" "..\backend\server.js"
    ) else (
        echo server.js not found in backend directory
    )
)

echo.
pause