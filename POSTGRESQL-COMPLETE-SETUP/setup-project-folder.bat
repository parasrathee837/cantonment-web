@echo off
color 0B
echo ===========================================================
echo    SETTING UP CBA PORTAL PROJECT FOLDERS
echo ===========================================================
echo.

:: Create main directory
echo Creating project directory at C:\CBA_Portal...
if not exist "C:\CBA_Portal" (
    mkdir "C:\CBA_Portal"
    echo ✓ Created C:\CBA_Portal
) else (
    echo ✓ C:\CBA_Portal already exists
)

echo.
echo ===========================================================
echo    COPY YOUR PROJECT FILES
echo ===========================================================
echo.
echo Please copy your "cantonment-web" folder to:
echo C:\CBA_Portal\
echo.
echo The structure should look like:
echo C:\CBA_Portal\
echo           └── cantonment-web\
echo                   ├── backend\
echo                   ├── database\
echo                   └── other files...
echo.
echo ===========================================================
echo.

:: Check if project exists
if exist "C:\CBA_Portal\cantonment-web\backend\package.json" (
    echo ✓ Project files found!
    echo.
    echo Your project is ready for installation.
) else (
    echo ⚠ Project files not found yet.
    echo.
    echo Please copy your cantonment-web folder to C:\CBA_Portal\
    echo then run this script again.
    echo.
    :: Open the folder for user
    explorer "C:\CBA_Portal"
)

echo.
pause