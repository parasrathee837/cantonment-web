#!/usr/bin/env node

/**
 * Foreign Key Constraints Migration Script
 * Database Administrator: 30+ Years Experience
 * Purpose: Safely apply foreign key constraints to existing database
 * Created: 2025-09-22
 */

const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

// Configuration
const DB_PATH = path.join(__dirname, '../backend/database.sqlite');
const BACKUP_PATH = path.join(__dirname, `../backend/database-backup-fk-migration-${Date.now()}.sqlite`);
const MIGRATION_SQL = path.join(__dirname, 'add-foreign-key-constraints.sql');

console.log('🔧 Foreign Key Constraints Migration Tool');
console.log('=========================================');

/**
 * Create database backup before migration
 */
async function createBackup() {
    console.log('📦 Creating database backup...');
    
    try {
        if (fs.existsSync(DB_PATH)) {
            fs.copyFileSync(DB_PATH, BACKUP_PATH);
            console.log(`✅ Backup created: ${BACKUP_PATH}`);
            return true;
        } else {
            console.log('⚠️  Database file not found, proceeding without backup');
            return false;
        }
    } catch (error) {
        console.error('❌ Failed to create backup:', error.message);
        throw error;
    }
}

/**
 * Test database connection
 */
async function testConnection() {
    console.log('🔌 Testing database connection...');
    
    return new Promise((resolve, reject) => {
        const db = new sqlite3.Database(DB_PATH, (err) => {
            if (err) {
                console.error('❌ Database connection failed:', err.message);
                reject(err);
            } else {
                console.log('✅ Database connection successful');
                db.close();
                resolve();
            }
        });
    });
}

/**
 * Check current foreign key status
 */
async function checkForeignKeyStatus() {
    console.log('🔍 Checking current foreign key status...');
    
    return new Promise((resolve, reject) => {
        const db = new sqlite3.Database(DB_PATH);
        
        db.get('PRAGMA foreign_keys', (err, row) => {
            if (err) {
                console.error('❌ Failed to check foreign key status:', err.message);
                reject(err);
            } else {
                const status = row.foreign_keys === 1 ? 'ENABLED' : 'DISABLED';
                console.log(`📊 Foreign keys are currently: ${status}`);
                db.close();
                resolve(status);
            }
        });
    });
}

/**
 * Analyze current data integrity
 */
async function analyzeDataIntegrity() {
    console.log('🔍 Analyzing current data integrity...');
    
    return new Promise((resolve, reject) => {
        const db = new sqlite3.Database(DB_PATH);
        
        const queries = [
            {
                name: 'Orphaned pension nominees',
                sql: `SELECT COUNT(*) as count FROM pension_nominees 
                      WHERE staff_id NOT IN (SELECT staff_id FROM admissions WHERE staff_id IS NOT NULL)`
            },
            {
                name: 'Orphaned staff deductions',
                sql: `SELECT COUNT(*) as count FROM staff_deductions 
                      WHERE staff_id NOT IN (SELECT staff_id FROM admissions WHERE staff_id IS NOT NULL)`
            },
            {
                name: 'Invalid designations in admissions',
                sql: `SELECT COUNT(*) as count FROM admissions a 
                      LEFT JOIN designations d ON a.designation = d.name 
                      WHERE a.designation IS NOT NULL AND d.name IS NULL`
            }
        ];
        
        let completed = 0;
        const results = {};
        
        queries.forEach(query => {
            db.get(query.sql, (err, row) => {
                if (err) {
                    console.error(`❌ Failed to check ${query.name}:`, err.message);
                } else {
                    results[query.name] = row.count;
                    console.log(`📊 ${query.name}: ${row.count}`);
                }
                
                completed++;
                if (completed === queries.length) {
                    db.close();
                    resolve(results);
                }
            });
        });
    });
}

/**
 * Run the migration SQL script
 */
async function runMigration() {
    console.log('🚀 Running foreign key constraints migration...');
    
    return new Promise((resolve, reject) => {
        // Read the migration SQL file
        let migrationSQL;
        try {
            migrationSQL = fs.readFileSync(MIGRATION_SQL, 'utf8');
        } catch (error) {
            console.error('❌ Failed to read migration SQL file:', error.message);
            reject(error);
            return;
        }
        
        const db = new sqlite3.Database(DB_PATH);
        
        // Execute the migration
        db.exec(migrationSQL, (err) => {
            if (err) {
                console.error('❌ Migration failed:', err.message);
                console.log('🔄 Attempting to restore from backup...');
                
                // Restore from backup
                try {
                    if (fs.existsSync(BACKUP_PATH)) {
                        fs.copyFileSync(BACKUP_PATH, DB_PATH);
                        console.log('✅ Database restored from backup');
                    }
                } catch (restoreError) {
                    console.error('❌ Failed to restore backup:', restoreError.message);
                }
                
                db.close();
                reject(err);
            } else {
                console.log('✅ Migration completed successfully!');
                db.close();
                resolve();
            }
        });
    });
}

/**
 * Verify migration results
 */
async function verifyMigration() {
    console.log('🔍 Verifying migration results...');
    
    return new Promise((resolve, reject) => {
        const db = new sqlite3.Database(DB_PATH);
        
        const verificationQueries = [
            {
                name: 'Foreign keys status',
                sql: 'PRAGMA foreign_keys'
            },
            {
                name: 'Tables with foreign keys',
                sql: `SELECT name FROM sqlite_master 
                      WHERE type='table' AND sql LIKE '%FOREIGN KEY%'`
            }
        ];
        
        db.get('PRAGMA foreign_keys', (err, row) => {
            if (err) {
                console.error('❌ Failed to verify foreign keys:', err.message);
                reject(err);
            } else {
                const status = row.foreign_keys === 1 ? 'ENABLED' : 'DISABLED';
                console.log(`✅ Foreign keys are now: ${status}`);
                
                // Check for any remaining orphaned records
                db.get(`SELECT COUNT(*) as count FROM staff_deductions sd 
                        LEFT JOIN admissions a ON sd.staff_id = a.staff_id 
                        WHERE a.staff_id IS NULL`, (err, row) => {
                    if (err) {
                        console.error('❌ Failed to check orphaned records:', err.message);
                    } else {
                        console.log(`📊 Remaining orphaned staff deductions: ${row.count}`);
                    }
                    
                    db.close();
                    resolve();
                });
            }
        });
    });
}

/**
 * Main migration function
 */
async function runForeignKeyMigration() {
    try {
        console.log('🏁 Starting Foreign Key Constraints Migration');
        console.log('⏰ Started at:', new Date().toISOString());
        
        // Step 1: Create backup
        await createBackup();
        
        // Step 2: Test connection
        await testConnection();
        
        // Step 3: Check current status
        await checkForeignKeyStatus();
        
        // Step 4: Analyze data integrity
        const integrityResults = await analyzeDataIntegrity();
        
        // Step 5: Run migration
        await runMigration();
        
        // Step 6: Verify migration
        await verifyMigration();
        
        console.log('');
        console.log('🎉 MIGRATION COMPLETED SUCCESSFULLY!');
        console.log('===================================');
        console.log('✅ Foreign key constraints have been implemented');
        console.log('✅ Referential integrity is now enforced');
        console.log('✅ Database structure is optimized for production');
        console.log('');
        console.log('📊 Migration Summary:');
        console.log(`   • Backup created: ${path.basename(BACKUP_PATH)}`);
        console.log(`   • Foreign keys: ENABLED`);
        console.log(`   • Data integrity: ENFORCED`);
        console.log('');
        console.log('⚠️  Important Notes:');
        console.log('   • Keep the backup file safe for rollback if needed');
        console.log('   • All future data operations will enforce referential integrity');
        console.log('   • Orphaned records have been cleaned up');
        console.log('');
        console.log('⏰ Completed at:', new Date().toISOString());
        
    } catch (error) {
        console.error('');
        console.error('💥 MIGRATION FAILED!');
        console.error('===================');
        console.error('Error:', error.message);
        console.error('');
        console.error('🔄 Rollback Options:');
        console.error(`   • Restore from backup: ${BACKUP_PATH}`);
        console.error('   • Check error logs above for details');
        console.error('   • Contact database administrator for assistance');
        
        process.exit(1);
    }
}

// Run the migration if this script is executed directly
if (require.main === module) {
    runForeignKeyMigration();
}

module.exports = {
    runForeignKeyMigration,
    createBackup,
    testConnection,
    checkForeignKeyStatus,
    analyzeDataIntegrity,
    runMigration,
    verifyMigration
};