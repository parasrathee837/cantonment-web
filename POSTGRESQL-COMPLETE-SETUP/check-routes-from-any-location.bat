@echo off
echo ===========================================
echo Check Routes From Any Location
echo ===========================================
echo.

echo Since we can't find your project root, let's check your running server
echo to see what endpoints actually exist:
echo.

echo Your server is running on localhost:5000
echo Let's test what endpoints are actually available:
echo.

echo Testing common user endpoints:
echo ==============================

echo 1. /api/users:
curl -s -w " [Status: %%{http_code}]" http://localhost:5000/api/users
echo.

echo 2. /api/auth:
curl -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth
echo.

echo 3. /api/auth/register:
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"test\",\"password\":\"test\"}" -s -w " [Status: %%{http_code}]" http://localhost:5000/api/auth/register
echo.

echo 4. /api/admin:
curl -s -w " [Status: %%{http_code}]" http://localhost:5000/api/admin
echo.

echo 5. /api/admin/users:
curl -s -w " [Status: %%{http_code}]" http://localhost:5000/api/admin/users
echo.

echo 6. /api/users-enhanced:
curl -s -w " [Status: %%{http_code}]" http://localhost:5000/api/users-enhanced
echo.

echo 7. /api/admissions:
curl -s -w " [Status: %%{http_code}]" http://localhost:5000/api/admissions
echo.

echo.
echo INTERPRETATION:
echo ==============
echo.
echo - 404 with HTML = Route doesn't exist
echo - 401 "No token" = Route exists, needs authentication  
echo - 200/201 with JSON = Route works
echo - 500 = Route exists but has errors
echo.

echo Based on the results above, we can determine:
echo 1. Which user endpoints actually exist
echo 2. What your frontend should call for user creation
echo 3. What your frontend should call for user deletion
echo.

echo FRONTEND DEBUGGING:
echo ===================
echo.
echo To see what your admin portal is actually trying to call:
echo 1. Open admin portal: http://localhost:5000
echo 2. Login as admin
echo 3. Press F12 (Developer Tools)
echo 4. Go to Network tab
echo 5. Try to create a user via popup
echo 6. See what POST request appears (if any)
echo 7. Try to delete a user 
echo 8. See what DELETE request appears
echo.
echo This will tell us exactly what endpoints your frontend expects!
echo.

echo WORKING ENDPOINTS FOUND:
echo ========================
echo From our tests, working endpoints appear to be:
findstr /C:"200" /C:"201" /C:"401" temp_results.txt 2>nul || echo "Run the tests above to see working endpoints"

pause