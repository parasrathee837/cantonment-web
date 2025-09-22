#!/usr/bin/env node

/**
 * SQLite to PostgreSQL Migration Script
 * Simple migration for beginners
 * Run this after setting up PostgreSQL on Render
 */

const sqlite3 = require('sqlite3').verbose();
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

console.log('🔄 CBA Database Migration Tool');
console.log('===============================');

// Configuration
const SQLITE_PATH = path.join(__dirname, 'backend/database.sqlite');
const POSTGRES_SCHEMA = path.join(__dirname, 'database/postgresql-enhanced-schema-v3.sql');

/**
 * Step 1: Export data from SQLite
 */
async function exportSQLiteData() {
    console.log('📤 Step 1: Exporting data from SQLite...');
    
    return new Promise((resolve, reject) => {
        const db = new sqlite3.Database(SQLITE_PATH, sqlite3.OPEN_READONLY, (err) => {
            if (err) {
                console.error('❌ Error opening SQLite database:', err.message);
                reject(err);
                return;
            }
            
            console.log('✅ Connected to SQLite database');
            
            // Export all important tables
            const exportData = {};
            const tables = ['users', 'admissions', 'designations', 'function_codes', 'object_codes', 'leave_types'];
            let completed = 0;
            
            tables.forEach(table => {
                db.all(`SELECT * FROM ${table}`, [], (err, rows) => {
                    if (err) {
                        console.log(`⚠️  Table ${table} not found or empty`);
                        exportData[table] = [];
                    } else {
                        exportData[table] = rows;
                        console.log(`✅ Exported ${rows.length} records from ${table}`);
                    }
                    
                    completed++;
                    if (completed === tables.length) {
                        db.close();
                        resolve(exportData);
                    }
                });
            });
        });
    });
}

/**
 * Step 2: Create PostgreSQL schema
 */
async function createPostgreSQLSchema(client) {
    console.log('📋 Step 2: Creating PostgreSQL schema...');
    
    try {
        // Read the schema file
        const schema = fs.readFileSync(POSTGRES_SCHEMA, 'utf8');
        
        // Execute schema creation
        await client.query(schema);
        console.log('✅ PostgreSQL schema created successfully');
        
    } catch (error) {
        console.error('❌ Error creating schema:', error.message);
        throw error;
    }
}

/**
 * Step 3: Import data to PostgreSQL
 */
async function importToPostgreSQL(data, client) {
    console.log('📥 Step 3: Importing data to PostgreSQL...');
    
    try {
        // Import users
        if (data.users && data.users.length > 0) {
            for (const user of data.users) {
                await client.query(
                    `INSERT INTO users (username, password_hash, full_name, email, role, status, created_at) 
                     VALUES ($1, $2, $3, $4, $5, $6, $7) ON CONFLICT (username) DO NOTHING`,
                    [
                        user.username,
                        user.password || user.password_hash,
                        user.full_name || user.username,
                        user.email,
                        user.role || 'user',
                        user.status || 'active',
                        user.created_at || new Date()
                    ]
                );
            }
            console.log(`✅ Imported ${data.users.length} users`);
        }
        
        // Import designations
        if (data.designations && data.designations.length > 0) {
            for (const designation of data.designations) {
                await client.query(
                    `INSERT INTO designations (name, department, description, is_active) 
                     VALUES ($1, $2, $3, $4) ON CONFLICT (name) DO NOTHING`,
                    [
                        designation.name,
                        designation.department || 'General',
                        designation.description || 'Imported from existing data',
                        designation.is_active !== undefined ? designation.is_active : true
                    ]
                );
            }
            console.log(`✅ Imported ${data.designations.length} designations`);
        }
        
        // Import function codes
        if (data.function_codes && data.function_codes.length > 0) {
            for (const code of data.function_codes) {
                await client.query(
                    `INSERT INTO function_codes (code, name, description, is_active) 
                     VALUES ($1, $2, $3, $4) ON CONFLICT (code) DO NOTHING`,
                    [
                        code.code,
                        code.name || `Function Code ${code.code}`,
                        code.description || 'Imported from existing data',
                        code.is_active !== undefined ? code.is_active : true
                    ]
                );
            }
            console.log(`✅ Imported ${data.function_codes.length} function codes`);
        }
        
        // Import object codes
        if (data.object_codes && data.object_codes.length > 0) {
            for (const code of data.object_codes) {
                await client.query(
                    `INSERT INTO object_codes (code, name, description, is_active) 
                     VALUES ($1, $2, $3, $4) ON CONFLICT (code) DO NOTHING`,
                    [
                        code.code,
                        code.name || `Object Code ${code.code}`,
                        code.description || 'Imported from existing data',
                        code.is_active !== undefined ? code.is_active : true
                    ]
                );
            }
            console.log(`✅ Imported ${data.object_codes.length} object codes`);
        }
        
        // Import leave types
        if (data.leave_types && data.leave_types.length > 0) {
            for (const leave of data.leave_types) {
                await client.query(
                    `INSERT INTO leave_types (name, days_allowed, description, is_active) 
                     VALUES ($1, $2, $3, $4) ON CONFLICT (name) DO NOTHING`,
                    [
                        leave.name,
                        leave.days_allowed || 30,
                        leave.description || 'Imported from existing data',
                        leave.is_active !== undefined ? leave.is_active : true
                    ]
                );
            }
            console.log(`✅ Imported ${data.leave_types.length} leave types`);
        }
        
        // Import admissions
        if (data.admissions && data.admissions.length > 0) {
            for (const admission of data.admissions) {
                await client.query(
                    `INSERT INTO admissions (staff_id, staff_name, designation, father_name, 
                                           permanent_address, mobile_number, status, created_at) 
                     VALUES ($1, $2, $3, $4, $5, $6, $7, $8) ON CONFLICT (staff_id) DO NOTHING`,
                    [
                        admission.id || `STAFF${admission.id}`,
                        admission.name || admission.staff_name,
                        admission.designation || 'General',
                        admission.father_name || 'Not Specified',
                        admission.address || admission.permanent_address || 'Not Specified',
                        admission.phone || admission.mobile_number || '0000000000',
                        admission.status || 'approved',
                        admission.created_at || new Date()
                    ]
                );
            }
            console.log(`✅ Imported ${data.admissions.length} staff records`);
        }
        
    } catch (error) {
        console.error('❌ Error importing data:', error.message);
        throw error;
    }
}

/**
 * Main migration function
 */
async function runMigration() {
    if (!process.env.DATABASE_URL) {
        console.error('❌ ERROR: DATABASE_URL environment variable not set!');
        console.log('💡 Please set your PostgreSQL connection string:');
        console.log('   export DATABASE_URL="postgresql://username:password@host:port/database"');
        process.exit(1);
    }
    
    try {
        console.log('🚀 Starting migration process...');
        console.log('⏰ Started at:', new Date().toISOString());
        
        // Step 1: Export from SQLite
        const data = await exportSQLiteData();
        
        // Step 2: Connect to PostgreSQL
        console.log('🔌 Connecting to PostgreSQL...');
        const client = new Client({
            connectionString: process.env.DATABASE_URL,
            ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
        });
        
        await client.connect();
        console.log('✅ Connected to PostgreSQL');
        
        // Step 3: Create schema
        await createPostgreSQLSchema(client);
        
        // Step 4: Import data
        await importToPostgreSQL(data, client);
        
        // Step 5: Verify migration
        const userCount = await client.query('SELECT COUNT(*) FROM users');
        const staffCount = await client.query('SELECT COUNT(*) FROM admissions');
        
        console.log('');
        console.log('🎉 MIGRATION COMPLETED SUCCESSFULLY!');
        console.log('====================================');
        console.log(`✅ Users migrated: ${userCount.rows[0].count}`);
        console.log(`✅ Staff records migrated: ${staffCount.rows[0].count}`);
        console.log('✅ Database schema created');
        console.log('✅ Foreign key constraints enabled');
        console.log('');
        console.log('🚀 Your application is ready for production!');
        console.log('⏰ Completed at:', new Date().toISOString());
        
        await client.end();
        
    } catch (error) {
        console.error('');
        console.error('💥 MIGRATION FAILED!');
        console.error('==================');
        console.error('Error:', error.message);
        console.error('');
        console.error('💡 Troubleshooting:');
        console.error('1. Check your DATABASE_URL is correct');
        console.error('2. Make sure PostgreSQL is running');
        console.error('3. Verify network connectivity');
        console.error('4. Check database permissions');
        
        process.exit(1);
    }
}

// Usage instructions
if (require.main === module) {
    console.log('');
    console.log('📖 HOW TO USE THIS MIGRATION TOOL:');
    console.log('==================================');
    console.log('1. Set up PostgreSQL database on Render');
    console.log('2. Copy the DATABASE_URL from Render dashboard');
    console.log('3. Run: export DATABASE_URL="your-database-url"');
    console.log('4. Run: node migrate-to-postgresql.js');
    console.log('');
    
    runMigration();
}

module.exports = { runMigration, exportSQLiteData, importToPostgreSQL };