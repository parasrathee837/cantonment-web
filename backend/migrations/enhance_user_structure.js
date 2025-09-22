const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, '../database.sqlite');

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error opening database:', err);
    process.exit(1);
  } else {
    console.log('Connected to SQLite database for user structure enhancement');
    enhanceUserStructure();
  }
});

function enhanceUserStructure() {
  db.serialize(() => {
    console.log('Starting user structure enhancement migration...');

    // Step 1: Add missing columns to users table
    console.log('Step 1: Adding new columns to users table...');
    
    const userColumns = [
      'full_name TEXT',
      'email TEXT',
      'phone TEXT',
      'status TEXT DEFAULT "active" CHECK(status IN ("active", "inactive"))',
      'date_of_birth DATE',
      'age INTEGER',
      'gender TEXT CHECK(gender IN ("Male", "Female", "Other"))',
      'father_name TEXT',
      'mother_name TEXT',
      'grand_father_name TEXT',
      'address TEXT',
      'mobile_number TEXT',
      'designation_id INTEGER',
      'appointment_date DATE',
      'aadhar_number TEXT',
      'pan_number TEXT',
      'profile_photo TEXT'
    ];

    // Add columns one by one (SQLite doesn't support adding multiple columns at once)
    let columnIndex = 0;
    
    function addNextColumn() {
      if (columnIndex >= userColumns.length) {
        console.log('Step 1 completed: All columns added to users table');
        createUserProfileTables();
        return;
      }

      const column = userColumns[columnIndex];
      const columnName = column.split(' ')[0];
      
      db.run(`ALTER TABLE users ADD COLUMN ${column}`, (err) => {
        if (err && !err.message.includes('duplicate column name')) {
          console.error(`Error adding column ${columnName}:`, err.message);
        } else {
          console.log(`✓ Added column: ${columnName}`);
        }
        columnIndex++;
        addNextColumn();
      });
    }
    
    addNextColumn();
  });
}

function createUserProfileTables() {
  console.log('Step 2: Creating user profile tables...');
  
  db.serialize(() => {
    // Create user_personal table for detailed personal information
    db.run(`CREATE TABLE IF NOT EXISTS user_personal (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE,
      full_name TEXT,
      date_of_birth DATE,
      age INTEGER,
      gender TEXT CHECK(gender IN ('Male', 'Female', 'Other')),
      father_name TEXT,
      mother_name TEXT,
      grand_father_name TEXT,
      marital_status TEXT,
      blood_group TEXT,
      nationality TEXT DEFAULT 'Indian',
      religion TEXT,
      category TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )`, (err) => {
      if (err) {
        console.error('Error creating user_personal table:', err);
      } else {
        console.log('✓ Created user_personal table');
      }
    });

    // Create user_contact table for contact information
    db.run(`CREATE TABLE IF NOT EXISTS user_contact (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE,
      email TEXT,
      mobile_number TEXT,
      phone TEXT,
      address TEXT,
      permanent_address TEXT,
      present_address TEXT,
      emergency_contact TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )`, (err) => {
      if (err) {
        console.error('Error creating user_contact table:', err);
      } else {
        console.log('✓ Created user_contact table');
      }
    });

    // Create user_professional table for professional information
    db.run(`CREATE TABLE IF NOT EXISTS user_professional (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE,
      designation_id INTEGER,
      designation TEXT,
      department TEXT,
      employee_id TEXT,
      employee_type TEXT,
      appointment_date DATE,
      date_of_joining DATE,
      office_number TEXT,
      function_code TEXT,
      object_code TEXT,
      status TEXT DEFAULT 'active' CHECK(status IN ('active', 'inactive', 'suspended')),
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
      FOREIGN KEY (designation_id) REFERENCES designations (id)
    )`, (err) => {
      if (err) {
        console.error('Error creating user_professional table:', err);
      } else {
        console.log('✓ Created user_professional table');
      }
    });

    // Create user_documents table for document information
    db.run(`CREATE TABLE IF NOT EXISTS user_documents (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE,
      aadhar_number TEXT,
      pan_number TEXT,
      voter_id TEXT,
      ration_card TEXT,
      driving_license TEXT,
      passport_number TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )`, (err) => {
      if (err) {
        console.error('Error creating user_documents table:', err);
      } else {
        console.log('✓ Created user_documents table');
      }
    });

    // Create user profile view for easy access to complete user information
    db.run(`CREATE VIEW IF NOT EXISTS user_complete_profile AS
      SELECT 
        u.id,
        u.username,
        u.role,
        u.status,
        u.created_at,
        u.updated_at,
        up.full_name,
        up.date_of_birth,
        up.age,
        up.gender,
        up.father_name,
        up.mother_name,
        up.grand_father_name,
        up.marital_status,
        up.blood_group,
        up.nationality,
        up.religion,
        up.category,
        uc.email,
        uc.mobile_number,
        uc.phone,
        uc.address,
        uc.permanent_address,
        uc.present_address,
        uc.emergency_contact,
        upr.designation_id,
        upr.designation,
        upr.department,
        upr.employee_id,
        upr.employee_type,
        upr.appointment_date,
        upr.date_of_joining,
        upr.office_number,
        upr.function_code,
        upr.object_code,
        ud.aadhar_number,
        ud.pan_number,
        ud.voter_id,
        ud.ration_card,
        ud.driving_license,
        ud.passport_number
      FROM users u
      LEFT JOIN user_personal up ON u.id = up.user_id
      LEFT JOIN user_contact uc ON u.id = uc.user_id
      LEFT JOIN user_professional upr ON u.id = upr.user_id
      LEFT JOIN user_documents ud ON u.id = ud.user_id
    `, (err) => {
      if (err) {
        console.error('Error creating user_complete_profile view:', err);
      } else {
        console.log('✓ Created user_complete_profile view');
      }
    });

    console.log('Step 2 completed: User profile tables created');
    console.log('User structure enhancement migration completed successfully!');
    
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