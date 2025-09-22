const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, '../database.sqlite');

class Database {
  constructor() {
    this.db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        console.error('Error opening database:', err);
      } else {
        console.log('Connected to SQLite database');
        // Enable foreign keys for SQLite
        this.db.run('PRAGMA foreign_keys = ON', (err) => {
          if (err) {
            console.error('Error enabling foreign keys:', err);
          } else {
            console.log('Foreign keys enabled');
          }
        });
        this.initDatabase();
      }
    });
  }

  initDatabase() {
    this.db.serialize(() => {
      // Users table
      this.db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'user',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // Designations table
      this.db.run(`CREATE TABLE IF NOT EXISTS designations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        department TEXT NOT NULL,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // Nationalities table
      this.db.run(`CREATE TABLE IF NOT EXISTS nationalities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        code TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // Admissions table
      this.db.run(`CREATE TABLE IF NOT EXISTS admissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        father_name TEXT NOT NULL,
        nationality TEXT,
        address TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        designation TEXT,
        photo_path TEXT,
        status TEXT DEFAULT 'pending',
        admission_date DATE,
        created_by INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // Insert default data
      this.db.run(`INSERT OR IGNORE INTO nationalities (name, code) VALUES 
        ('Indian', 'IND'),
        ('Pakistani', 'PAK'),
        ('Bangladeshi', 'BGD'),
        ('Nepalese', 'NPL'),
        ('Sri Lankan', 'LKA'),
        ('Other', 'OTH')`);

      this.db.run(`INSERT OR IGNORE INTO designations (name, department, description) VALUES 
        ('Chief Executive Officer', 'Administration', 'Head of cantonment board'),
        ('Executive Officer', 'Administration', 'Senior administrative officer'),
        ('Assistant Engineer', 'Engineering', 'Engineering department assistant'),
        ('Junior Engineer', 'Engineering', 'Junior level engineer'),
        ('Accountant', 'Finance', 'Financial operations'),
        ('Medical Officer', 'Health', 'Healthcare services'),
        ('Security Officer', 'Security', 'Security and safety'),
        ('Sanitation Inspector', 'Health', 'Sanitation oversight'),
        ('Tax Collector', 'Finance', 'Revenue collection'),
        ('Store Keeper', 'Administration', 'Inventory management')`);

      // Create ps_verifications table for payroll verification
      this.db.run(`CREATE TABLE IF NOT EXISTS ps_verifications (
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
      )`);

      // Create default admin user (password: admin123)
      const bcrypt = require('bcryptjs');
      const hashedPassword = bcrypt.hashSync('admin123', 12);
      this.db.run(`INSERT OR IGNORE INTO users (username, password, role) VALUES ('admin', ?, 'admin')`, [hashedPassword]);
    });
  }

  query(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.all(sql, params, (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  run(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.run(sql, params, function(err) {
        if (err) {
          reject(err);
        } else {
          resolve({ id: this.lastID, changes: this.changes });
        }
      });
    });
  }

  close() {
    return new Promise((resolve, reject) => {
      this.db.close((err) => {
        if (err) reject(err);
        else resolve();
      });
    });
  }
}

const database = new Database();
module.exports = database;