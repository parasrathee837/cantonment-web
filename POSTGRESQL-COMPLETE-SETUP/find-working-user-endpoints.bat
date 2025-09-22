@echo off
echo ===========================================
echo Find Working User Endpoints
echo ===========================================
echo.

echo Since users-normalized doesn't exist, let's find what actually works:
echo.

echo Testing all possible user endpoints:
echo.

echo 1. Testing /api/users (GET):
curl -s -w "Status: %%{http_code} | " http://localhost:5000/api/users
echo.

echo 2. Testing /api/users-enhanced (GET):
curl -s -w "Status: %%{http_code} | " http://localhost:5000/api/users-enhanced
echo.

echo 3. Testing /api/auth (GET):
curl -s -w "Status: %%{http_code} | " http://localhost:5000/api/auth
echo.

echo 4. Testing /api/auth/register (POST):
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"testapi\",\"password\":\"test123\"}" -s -w "Status: %%{http_code} | " http://localhost:5000/api/auth/register
echo.

echo 5. Testing /api/admin/users (GET):
curl -s -w "Status: %%{http_code} | " http://localhost:5000/api/admin/users
echo.

echo 6. Testing /api/admissions (GET):
curl -s -w "Status: %%{http_code} | " http://localhost:5000/api/admissions
echo.

echo.
echo ANALYSIS:
echo ========
echo.
echo Look for responses that are NOT 404 "Cannot GET/POST":
echo - 401 = Route exists, needs authentication
echo - 200/201 = Route works  
echo - 500 = Route exists but has errors
echo - 404 with HTML = Route doesn't exist
echo.

echo Based on the responses above, we can determine:
echo 1. Which routes actually exist in your backend
echo 2. What your frontend should be calling
echo 3. How to fix the user creation/deletion
echo.

echo FRONTEND FIX:
echo =============
echo.
echo Your admin portal popup probably needs to use:
echo - A working auth endpoint for user creation
echo - A working users endpoint for deletion
echo.

echo We need to identify these working endpoints first!
echo.

pause