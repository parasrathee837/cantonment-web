@echo off
echo ===========================================
echo Debug: Why User Creation Isn't Working
echo ===========================================
echo.

echo If the live tracker shows no new records when you create a user,
echo it means the "Create new user" popup is FAILING to save to database.
echo.

echo POSSIBLE CAUSES:
echo ================
echo.
echo 1. Frontend popup sends data to backend
echo 2. Backend receives the request but fails to save
echo 3. Database error prevents insertion
echo 4. User creation endpoint doesn't exist
echo.

echo DEBUGGING STEPS:
echo ================
echo.

echo Step 1: Check browser Developer Tools
echo ------------------------------------
echo 1. Open your admin portal
echo 2. Press F12 to open Developer Tools
echo 3. Go to Network tab
echo 4. Try to create a user via popup
echo 5. Look for the POST request (usually to /api/users or similar)
echo 6. Check if request fails (red color) or succeeds (green)
echo 7. Click on the request to see response
echo.

echo Step 2: Check backend console
echo -----------------------------
echo 1. Look at your backend server console window
echo 2. Try to create a user via popup
echo 3. Look for any error messages like:
echo    - "relation does not exist"
echo    - "column does not exist" 
echo    - "authentication failed"
echo    - Route not found errors
echo.

echo Step 3: Test user creation endpoint manually
echo --------------------------------------------
echo.

set /p test_endpoint="Test user creation endpoint manually? (Y/N): "
if /i "%test_endpoint%"=="Y" (
    echo.
    echo Testing common user creation endpoints...
    echo.
    
    echo Testing POST /api/users:
    curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"curltest\",\"password\":\"test123\",\"role\":\"user\"}" -s -w "Status: %%{http_code}\n" http://localhost:5000/api/users
    
    echo.
    echo Testing POST /api/users-normalized:
    curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"curltest2\",\"password\":\"test123\",\"role\":\"user\"}" -s -w "Status: %%{http_code}\n" http://localhost:5000/api/users-normalized
    
    echo.
    echo Testing POST /api/users-enhanced:
    curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"curltest3\",\"password\":\"test123\",\"role\":\"user\"}" -s -w "Status: %%{http_code}\n" http://localhost:5000/api/users-enhanced
    
    echo.
    echo If any of these worked, check database:
    
    set PGHOST=localhost
    set PGPORT=5432
    set PGDATABASE=cba_portal
    set PGUSER=postgres
    set PGPASSWORD=CBA@2025Portal
    
    psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -c "SELECT id, username, role FROM users WHERE username LIKE 'curltest%%';"
)

echo.
echo Step 4: Check what happens in popup
echo -----------------------------------
echo.
echo When you click "Create new user" in admin portal:
echo 1. Does popup open successfully?
echo 2. Can you fill in the form fields?
echo 3. When you click Save/Submit, do you get any error messages?
echo 4. Does popup close or stay open with error?
echo.

echo COMMON ISSUES:
echo ==============
echo.
echo Issue 1: Authentication problem
echo - Popup request needs admin authentication
echo - Your admin session might have expired
echo - Try logging out and logging back in
echo.

echo Issue 2: Missing database tables
echo - Backend tries to insert into tables that don't exist
echo - Check backend console for "relation does not exist" errors
echo.

echo Issue 3: Form validation errors
echo - Required fields not filled
echo - Invalid data format
echo - Check popup for error messages
echo.

echo Issue 4: Route not registered
echo - Backend doesn't have the user creation route
echo - Check backend console for route loading errors
echo.

echo NEXT STEPS:
echo ==========
echo.
echo 1. Try creating user again with Developer Tools open (F12)
echo 2. Check Network tab for failed requests
echo 3. Check Console tab for JavaScript errors
echo 4. Check backend server console for errors
echo 5. Report what you see!
echo.

pause