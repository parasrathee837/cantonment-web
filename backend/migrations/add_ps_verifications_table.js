const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, '../database.sqlite');

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error opening database:', err);
    process.exit(1);
  } else {
    console.log('Connected to SQLite database');
    createPSVerificationsTable();
  }
});

function createPSVerificationsTable() {
  db.serialize(() => {
    // Create ps_verifications table
    db.run(`CREATE TABLE IF NOT EXISTS ps_verifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      staff_id TEXT NOT NULL UNIQUE,
      status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'approved', 'rejected')),
      approved_by TEXT,
      approved_date DATETIME,
      rejected_by TEXT,
      rejected_date DATETIME,
      remarks TEXT,
      created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_date DATETIME DEFAULT CURRENT_TIMESTAMP
    )`, (err) => {
      if (err) {
        console.error('Error creating ps_verifications table:', err);
      } else {
        console.log('ps_verifications table created successfully');
        
        // Initialize PS verification records for existing staff
        initializePSVerificationRecords();
      }
    });
  });
}

function initializePSVerificationRecords() {
  // Insert PS verification records for all approved staff that don't have them
  const query = `
    INSERT OR IGNORE INTO ps_verifications (staff_id, status, created_date, updated_date)
    SELECT staffId, 'pending', datetime('now'), datetime('now')
    FROM admissions
    WHERE status = 'approved'
    AND staffId IS NOT NULL
    AND staffId NOT IN (SELECT staff_id FROM ps_verifications)
  `;
  
  db.run(query, function(err) {
    if (err) {
      console.error('Error initializing PS verification records:', err);
    } else {
      console.log(`Initialized ${this.changes} PS verification records`);
    }
    
    // Close the database connection
    db.close((err) => {
      if (err) {
        console.error('Error closing database:', err);
      } else {
        console.log('Database connection closed');
      }
    });
  });
}