@echo off
echo ===========================================
echo Check Admin Session and Authentication
echo ===========================================
echo.

echo If user creation isn't working, it might be an authentication issue.
echo.

echo QUICK CHECKS:
echo ============
echo.

echo 1. Are you properly logged into admin portal?
set /p logged_in="Are you currently logged into the admin portal? (Y/N): "

if /i "%logged_in%"=="N" (
    echo.
    echo Please login to admin portal first:
    echo 1. Go to http://localhost:5000
    echo 2. Login with your admin credentials
    echo 3. Then try creating users
    pause
    exit /b 0
)

echo.
echo 2. Test if admin session is working
echo.

echo Testing admin-only endpoints to verify your session:
echo.

echo Testing /api/admin endpoint:
curl -s -w "Status: %%{http_code}\n" http://localhost:5000/api/admin

echo.
echo Testing /api/users endpoint with admin session:
curl -s -w "Status: %%{http_code}\n" http://localhost:5000/api/users

echo.
echo If you get 401 errors above, your admin session expired.
echo.

echo SOLUTION: Refresh your admin login
echo =================================
echo.

echo 1. Go to your admin portal tab
echo 2. Refresh the page (F5)
echo 3. Login again if prompted
echo 4. Try creating user again
echo.

echo OR try opening admin portal in new tab:
echo.
set /p open_new="Open admin portal in new browser tab? (Y/N): "
if /i "%open_new%"=="Y" (
    start http://localhost:5000
    echo.
    echo New tab opened. Login and try creating user there.
)

echo.
echo DEBUGGING WORKFLOW:
echo ==================
echo.
echo After ensuring you're logged in:
echo 1. Open admin portal
echo 2. Press F12 (Developer Tools)
echo 3. Go to Network tab
echo 4. Try to create a user
echo 5. Look for POST request to user creation endpoint
echo 6. Check if it's successful (green) or failed (red)
echo.

pause