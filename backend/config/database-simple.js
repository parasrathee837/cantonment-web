const { Pool } = require('pg');

// Simple PostgreSQL Configuration - No SSL
const pool = new Pool({
    user: 'cba_admin',
    host: '192.168.0.147', 
    database: 'cba_portal',
    password: 'q1w2e3r4',
    port: 5432,
    ssl: false
});

module.exports = pool;