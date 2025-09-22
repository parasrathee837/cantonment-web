@echo off
echo ===========================================
echo CBA Portal - JSON Error Debugging
echo ===========================================
echo.

echo This will help diagnose the JSON parsing error you're seeing.
echo.

echo 1. Testing if backend server is running...
curl -s http://localhost:5000/api/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Backend server is responding
) else (
    echo [ERROR] Backend server is not responding on port 5000
    echo Please start your backend server first.
    pause
    exit /b 1
)

echo.
echo 2. Testing API endpoints...
echo.

echo Testing /api/users endpoint:
curl -s -w "Status: %%{http_code}\n" http://localhost:5000/api/users

echo.
echo Testing /api/admissions endpoint:
curl -s -w "Status: %%{http_code}\n" http://localhost:5000/api/admissions

echo.
echo Testing /api/designations endpoint:
curl -s -w "Status: %%{http_code}\n" http://localhost:5000/api/designations

echo.
echo 3. Checking backend logs...
echo Look for error messages in your backend console.
echo.

echo 4. Common causes of JSON parse errors:
echo - Backend returning HTML error page instead of JSON
echo - Database connection issues
echo - Missing tables causing 500 errors
echo - CORS issues
echo - Backend server crashed
echo.

echo 5. Solutions to try:
echo - Restart your backend server
echo - Check backend console for error messages
echo - Run create-all-missing-tables.bat to fix database
echo - Check if all required npm packages are installed
echo.

pause