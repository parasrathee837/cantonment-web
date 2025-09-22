@echo off
echo ===========================================================
echo   FIXING DATABASE.JS CORRUPTION - WINDOWS
echo ===========================================================
echo.
echo The database.js file has corrupted characters (^) that
echo need to be removed.
echo.
pause

cd /d "C:\CBA_Portal\cantonment-web\backend\config"

echo Backing up corrupted database.js...
if exist database.js ren database.js database-corrupted.js

echo Creating clean database.js...
echo const sqlite3 = require('sqlite3'^).verbose(^); > database.js
echo const path = require('path'^); >> database.js
echo. >> database.js
echo const dbPath = path.join(__dirname, '../database.sqlite'^); >> database.js
echo. >> database.js
echo class Database { >> database.js
echo   constructor(^) { >> database.js
echo     this.db = new sqlite3.Database(dbPath, (err^) =^> { >> database.js
echo       if (err^) { >> database.js
echo         console.error('Error opening database:', err^); >> database.js
echo       } else { >> database.js
echo         console.log('Connected to SQLite database'^); >> database.js
echo         this.db.run('PRAGMA foreign_keys = ON', (err^) =^> { >> database.js
echo           if (err^) { >> database.js
echo             console.error('Error enabling foreign keys:', err^); >> database.js
echo           } else { >> database.js
echo             console.log('Foreign keys enabled'^); >> database.js
echo           } >> database.js
echo         }^); >> database.js
echo         this.initDatabase(^); >> database.js
echo       } >> database.js
echo     }^); >> database.js
echo   } >> database.js
echo. >> database.js
echo   async query(sql, params = []^) { >> database.js
echo     return new Promise((resolve, reject^) =^> { >> database.js
echo       this.db.all(sql, params, (err, rows^) =^> { >> database.js
echo         if (err^) reject(err^); >> database.js
echo         else resolve(rows^); >> database.js
echo       }^); >> database.js
echo     }^); >> database.js
echo   } >> database.js
echo. >> database.js
echo   async run(sql, params = []^) { >> database.js
echo     return new Promise((resolve, reject^) =^> { >> database.js
echo       this.db.run(sql, params, function(err^) { >> database.js
echo         if (err^) reject(err^); >> database.js
echo         else resolve({ id: this.lastID, changes: this.changes }^); >> database.js
echo       }^); >> database.js
echo     }^); >> database.js
echo   } >> database.js
echo. >> database.js
echo   async close(^) { >> database.js
echo     return new Promise((resolve, reject^) =^> { >> database.js
echo       this.db.close((err^) =^> { >> database.js
echo         if (err^) reject(err^); >> database.js
echo         else resolve(^); >> database.js
echo       }^); >> database.js
echo     }^); >> database.js
echo   } >> database.js
echo } >> database.js
echo. >> database.js
echo const database = new Database(^); >> database.js
echo module.exports = database; >> database.js

echo FIXING CORRUPTED CHARACTERS...
powershell -Command "(Get-Content database.js) -replace '\^', '' | Set-Content database.js"

echo Testing syntax...
node -c database.js
if errorlevel 1 (
    echo FAILED - Database.js still has syntax errors
    echo Restoring original file...
    if exist database-corrupted.js ren database-corrupted.js database.js
    pause
    exit /b 1
)

echo ✓ SUCCESS - Database.js fixed!
echo.
echo Now try: start-cba-portal-postgresql.bat
echo.
pause