@echo off
color 0C
echo ===========================================================
echo   REPLACING SQLITE DATABASE.JS WITH POSTGRESQL VERSION
echo ===========================================================
echo.
echo This will replace the SQLite database.js file with a 
echo PostgreSQL-only version to fix the "Cannot find module sqlite3" error.
echo.
pause

cd /d "C:\CBA_Portal\cantonment-web\backend\config"

echo Backing up old database.js...
if exist database.js ren database.js database-sqlite-backup.js

echo Creating PostgreSQL-only database.js...
(
echo const { Pool } = require('pg'^);
echo require('dotenv'^).config(^);
echo.
echo const pool = new Pool(^{
echo   host: process.env.DB_HOST ^|^| 'localhost',
echo   port: process.env.DB_PORT ^|^| 5432,
echo   database: process.env.DB_NAME ^|^| 'cba_portal',
echo   user: process.env.DB_USER ^|^| 'cba_admin',
echo   password: process.env.DB_PASSWORD ^|^| 'CBA@2025Portal',
echo   max: 20,
echo   idleTimeoutMillis: 30000,
echo   connectionTimeoutMillis: 2000,
echo }^);
echo.
echo class Database {
echo   constructor(^) {
echo     this.pool = pool;
echo     console.log('PostgreSQL Database initialized'^);
echo   }
echo.
echo   async query(sql, params = []^) {
echo     try {
echo       const result = await this.pool.query(sql, params^);
echo       return result.rows;
echo     } catch (error^) {
echo       console.error('Database query error:', error^);
echo       throw error;
echo     }
echo   }
echo.
echo   async run(sql, params = []^) {
echo     try {
echo       const result = await this.pool.query(sql, params^);
echo       return {
echo         id: result.rows[0] ? result.rows[0].id : null,
echo         changes: result.rowCount
echo       };
echo     } catch (error^) {
echo       console.error('Database run error:', error^);
echo       throw error;
echo     }
echo   }
echo.
echo   async get(sql, params = []^) {
echo     try {
echo       const result = await this.pool.query(sql, params^);
echo       return result.rows[0] ^|^| null;
echo     } catch (error^) {
echo       console.error('Database get error:', error^);
echo       throw error;
echo     }
echo   }
echo.
echo   async all(sql, params = []^) {
echo     try {
echo       const result = await this.pool.query(sql, params^);
echo       return result.rows;
echo     } catch (error^) {
echo       console.error('Database all error:', error^);
echo       throw error;
echo     }
echo   }
echo.
echo   async close(^) {
echo     try {
echo       await this.pool.end(^);
echo       console.log('PostgreSQL connection pool closed'^);
echo     } catch (error^) {
echo       console.error('Error closing database:', error^);
echo     }
echo   }
echo }
echo.
echo const database = new Database(^);
echo module.exports = database;
) > database.js

echo Removing ^ characters...
powershell -Command "(Get-Content database.js) -replace '\^', '' | Set-Content database.js"

echo Testing syntax...
node -c database.js
if errorlevel 1 (
    echo ❌ FAILED - Still has syntax errors
    echo Restoring backup...
    if exist database-sqlite-backup.js ren database-sqlite-backup.js database.js
    pause
    exit /b 1
)

echo ✓ SUCCESS - PostgreSQL database.js created!

echo.
echo ===========================================================
echo   ✓ DATABASE.JS REPLACED WITH POSTGRESQL VERSION!
echo ===========================================================
echo.
echo Changes made:
echo ✓ Replaced SQLite database.js with PostgreSQL version
echo ✓ No more sqlite3 dependency required
echo ✓ Direct PostgreSQL connection
echo ✓ Same API interface maintained
echo.
echo Now try: start-cba-portal-postgresql.bat
echo.
pause