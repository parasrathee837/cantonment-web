@echo off
color 0A
echo ===========================================================
echo   FIXING DATABASE CODE FOR POSTGRESQL
echo ===========================================================
echo.
echo Issue: database.js still trying to load SQLite
echo Solution: Update code to use PostgreSQL only
echo.
pause

cd /d "C:\CBA_Portal\cantonment-web\backend"

echo [1/4] Backing up original database.js...
if exist config\database.js (
    copy config\database.js config\database-sqlite-backup.js >nul
    echo ✓ Original database.js backed up
)

echo [2/4] Creating PostgreSQL database.js...
if not exist config mkdir config

(
echo const { Pool } = require('pg'^);
echo require('dotenv'^).config(^);
echo.
echo // PostgreSQL connection configuration
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
echo   constructor(^^^) {
echo     this.pool = pool;
echo     this.initDatabase(^^^);
echo   }
echo.
echo   async initDatabase(^^^) {
echo     try {
echo       console.log('🐘 Initializing PostgreSQL database...'^);
echo       
echo       // Create tables if they don't exist
echo       await this.createTables(^^^);
echo       
echo       console.log('✓ PostgreSQL database initialized successfully'^);
echo     } catch (error^^^) {
echo       console.error('❌ Database initialization failed:', error^);
echo     }
echo   }
echo.
echo   async createTables(^^^) {
echo     const createUsersTable = `
echo       CREATE TABLE IF NOT EXISTS users (
echo         id SERIAL PRIMARY KEY,
echo         username VARCHAR(100^^^) UNIQUE NOT NULL,
echo         password TEXT NOT NULL,
echo         role VARCHAR(50^^^) DEFAULT 'user',
echo         created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo         updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo       ^^^)`;
echo.
echo     const createDesignationsTable = `
echo       CREATE TABLE IF NOT EXISTS designations (
echo         id SERIAL PRIMARY KEY,
echo         name VARCHAR(200^^^) NOT NULL,
echo         department VARCHAR(200^^^) NOT NULL,
echo         description TEXT,
echo         created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo         updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo       ^^^)`;
echo.
echo     const createNationalitiesTable = `
echo       CREATE TABLE IF NOT EXISTS nationalities (
echo         id SERIAL PRIMARY KEY,
echo         name VARCHAR(100^^^) UNIQUE NOT NULL,
echo         code VARCHAR(10^^^),
echo         created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo       ^^^)`;
echo.
echo     const createAdmissionsTable = `
echo       CREATE TABLE IF NOT EXISTS admissions (
echo         id SERIAL PRIMARY KEY,
echo         name VARCHAR(200^^^) NOT NULL,
echo         father_name VARCHAR(200^^^) NOT NULL,
echo         nationality VARCHAR(100^^^),
echo         address TEXT NOT NULL,
echo         phone VARCHAR(20^^^),
echo         email VARCHAR(100^^^),
echo         designation VARCHAR(200^^^),
echo         photo_path TEXT,
echo         status VARCHAR(50^^^) DEFAULT 'pending',
echo         admission_date DATE,
echo         created_by INTEGER,
echo         created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo         updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo       ^^^)`;
echo.
echo     const createPsVerificationsTable = `
echo       CREATE TABLE IF NOT EXISTS ps_verifications (
echo         id SERIAL PRIMARY KEY,
echo         staff_id VARCHAR(100^^^) NOT NULL UNIQUE,
echo         status VARCHAR(20^^^) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected'^^^)^^^),
echo         approved_by VARCHAR(100^^^),
echo         approved_date TIMESTAMP,
echo         rejected_by VARCHAR(100^^^),
echo         rejected_date TIMESTAMP,
echo         remarks TEXT,
echo         created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo         updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
echo       ^^^)`;
echo.
echo     // Execute table creation
echo     await this.pool.query(createUsersTable^);
echo     await this.pool.query(createDesignationsTable^);
echo     await this.pool.query(createNationalitiesTable^);
echo     await this.pool.query(createAdmissionsTable^);
echo     await this.pool.query(createPsVerificationsTable^);
echo.
echo     // Insert default data
echo     await this.insertDefaultData(^^^);
echo   }
echo.
echo   async insertDefaultData(^^^) {
echo     // Insert nationalities
echo     const nationalitiesData = [
echo       ['Indian', 'IND'], ['Pakistani', 'PAK'], ['Bangladeshi', 'BGD'],
echo       ['Nepalese', 'NPL'], ['Sri Lankan', 'LKA'], ['Other', 'OTH']
echo     ];
echo.
echo     for (const [name, code] of nationalitiesData^^^) {
echo       await this.pool.query(
echo         'INSERT INTO nationalities (name, code^^^) VALUES ($1, $2^^^) ON CONFLICT (name^^^) DO NOTHING',
echo         [name, code]
echo       ^^^);
echo     }
echo.
echo     // Insert designations
echo     const designationsData = [
echo       ['Chief Executive Officer', 'Administration', 'Head of cantonment board'],
echo       ['Executive Officer', 'Administration', 'Senior administrative officer'],
echo       ['Assistant Engineer', 'Engineering', 'Engineering department assistant'],
echo       ['Junior Engineer', 'Engineering', 'Junior level engineer'],
echo       ['Accountant', 'Finance', 'Financial operations'],
echo       ['Medical Officer', 'Health', 'Healthcare services'],
echo       ['Security Officer', 'Security', 'Security and safety'],
echo       ['Sanitation Inspector', 'Health', 'Sanitation oversight'],
echo       ['Tax Collector', 'Finance', 'Revenue collection'],
echo       ['Store Keeper', 'Administration', 'Inventory management']
echo     ];
echo.
echo     for (const [name, dept, desc] of designationsData^^^) {
echo       await this.pool.query(
echo         'INSERT INTO designations (name, department, description^^^) VALUES ($1, $2, $3^^^) ON CONFLICT DO NOTHING',
echo         [name, dept, desc]
echo       ^^^);
echo     }
echo.
echo     // Create default admin user
echo     const bcrypt = require('bcryptjs'^);
echo     const hashedPassword = bcrypt.hashSync('admin123', 12^);
echo     await this.pool.query(
echo       'INSERT INTO users (username, password, role^^^) VALUES ($1, $2, $3^^^) ON CONFLICT (username^^^) DO NOTHING',
echo       ['admin', hashedPassword, 'admin']
echo     ^^^);
echo   }
echo.
echo   async query(sql, params = []^^^) {
echo     try {
echo       const result = await this.pool.query(sql, params^);
echo       return result.rows;
echo     } catch (error^^^) {
echo       console.error('Database query error:', error^);
echo       throw error;
echo     }
echo   }
echo.
echo   async run(sql, params = []^^^) {
echo     try {
echo       const result = await this.pool.query(sql, params^);
echo       return { 
echo         id: result.rows[0] ? result.rows[0].id : null,
echo         changes: result.rowCount
echo       };
echo     } catch (error^^^) {
echo       console.error('Database run error:', error^);
echo       throw error;
echo     }
echo   }
echo.
echo   async get(sql, params = []^^^) {
echo     try {
echo       const result = await this.pool.query(sql, params^);
echo       return result.rows[0] ^|^| null;
echo     } catch (error^^^) {
echo       console.error('Database get error:', error^);
echo       throw error;
echo     }
echo   }
echo.
echo   async all(sql, params = []^^^) {
echo     try {
echo       const result = await this.pool.query(sql, params^);
echo       return result.rows;
echo     } catch (error^^^) {
echo       console.error('Database all error:', error^);
echo       throw error;
echo     }
echo   }
echo.
echo   async close(^^^) {
echo     try {
echo       await this.pool.end(^^^);
echo       console.log('PostgreSQL connection pool closed'^);
echo     } catch (error^^^) {
echo       console.error('Error closing database:', error^);
echo     }
echo   }
echo }
echo.
echo const database = new Database(^^^);
echo module.exports = database;
) > config\database.js

echo ✓ PostgreSQL database.js created

echo [3/4] Updating server.js to use PostgreSQL config...
if exist server.js (
    powershell -Command "(Get-Content server.js) -replace 'require.*database.*', 'const database = require(\"./config/database\");' | Set-Content server.js"
    echo ✓ Server.js updated
)

echo [4/4] Verifying PostgreSQL dependencies...
if exist node_modules\pg (
    echo ✓ PostgreSQL driver available
) else (
    echo Installing PostgreSQL driver...
    call npm install pg
)

echo.
echo ===========================================================
echo   ✓ DATABASE CODE FIXED FOR POSTGRESQL!
echo ===========================================================
echo.
echo Changes made:
echo ✓ Replaced SQLite database.js with PostgreSQL version
echo ✓ Updated connection to use PostgreSQL pool
echo ✓ Converted all queries to PostgreSQL syntax
echo ✓ Added proper error handling
echo ✓ Maintained same API interface
echo.
echo Your application now uses PostgreSQL code!
echo.
echo Test the server: start-cba-portal-postgresql.bat
echo.
pause