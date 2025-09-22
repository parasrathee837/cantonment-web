@echo off
echo ===========================================
echo FIX SERVER ROUTE REGISTRATION ISSUES
echo ===========================================
echo.

echo PROBLEM IDENTIFIED:
echo ==================
echo Your server.js is configured correctly, but the route files might be missing key endpoints.
echo.
echo From your tests:
echo - /api/auth/login returns 404 (but should work)
echo - /api/auth/register returns 500 error (but should work)  
echo - /api/users returns 404 (but should work)
echo - Only /api/admissions returns 401 (works but needs auth)
echo.

echo Let's check what's actually happening:
echo ======================================
echo.

echo 1. First, restart your server and check for startup errors
echo 2. Your server console should show any route loading errors
echo.

echo MANUAL DEBUGGING STEPS:
echo =======================
echo.
echo 1. Stop your current server (Ctrl+C in server window)
echo 2. Start it again and watch for these messages:
echo    - "Server running on port 5000" 
echo    - Any "Cannot find module" errors
echo    - Any "Error loading routes" messages
echo.
echo 3. If you see module errors, the route files have dependencies that don't exist
echo.

echo Let's test with a simple endpoint first:
echo ========================================
echo.

echo Testing the health endpoint (should always work):
curl -s http://localhost:5000/api/health
echo.
echo.

echo If health endpoint works, the server is fine. If not, server has issues.
echo.

echo MOST LIKELY CAUSES:
echo ===================
echo.
echo 1. Route files are trying to import missing modules
echo 2. Database connection failures in route files
echo 3. Middleware dependencies missing
echo 4. Route files have syntax errors
echo.

echo QUICK FIX TEST:
echo ===============
echo.
echo Let's create a simple test user using the working /api/admin endpoint:
echo.

echo Step 1: Get admin token
curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin123\"}" -s http://localhost:5000/api/auth/login > token_response.txt

echo Login response:
type token_response.txt
echo.

echo Step 2: Extract token manually and test admin user creation
echo You need to copy the token from the JSON above and run:
echo.
echo curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer YOUR_TOKEN" -d "{\"username\":\"quicktest\",\"full_name\":\"Quick Test User\",\"email\":\"quick@test.com\",\"password\":\"password123\",\"role\":\"user\"}" http://localhost:5000/api/admin/users
echo.

echo FINAL SOLUTION:
echo ===============
echo.
echo If /api/admin/users works for user creation (which it should based on our earlier findings),
echo then update your frontend to call:
echo - /api/admin/users for user creation (with admin auth)
echo - /api/admin/users/:id for user deletion (with admin auth)
echo.
echo Instead of the broken /api/users endpoints.
echo.

del token_response.txt 2>nul
pause