const { Pool } = require('pg');

// PostgreSQL Database Configuration for CBA Portal
class PostgreSQLDatabase {
    constructor() {
        this.pool = new Pool({
            user: process.env.DB_USER || 'cba_admin',
            host: process.env.DB_HOST || 'localhost',
            database: process.env.DB_NAME || 'cba_portal',
            password: process.env.DB_PASSWORD || 'CBA@2025Portal',
            port: process.env.DB_PORT || 5432,
            
            // Connection pool settings
            max: 20, // Maximum number of clients in the pool
            idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
            connectionTimeoutMillis: 2000, // Return error after 2 seconds if connection could not be established
            
            // SSL configuration - disabled for local connections
            ssl: false,
        });

        // Handle pool errors
        this.pool.on('error', (err, client) => {
            console.error('Unexpected error on idle client', err);
            process.exit(-1);
        });

        console.log(`🐘 PostgreSQL Database connected to ${this.pool.options.database}@${this.pool.options.host}:${this.pool.options.port}`);
    }

    // Execute a query and return results
    async query(text, params = []) {
        const start = Date.now();
        try {
            const result = await this.pool.query(text, params);
            const duration = Date.now() - start;
            
            if (process.env.NODE_ENV === 'development') {
                console.log('🔍 Query executed:', {
                    text: text.substring(0, 100) + '...',
                    duration: `${duration}ms`,
                    rows: result.rowCount
                });
            }
            
            return result.rows;
        } catch (error) {
            console.error('❌ Database query error:', {
                text: text.substring(0, 100) + '...',
                error: error.message,
                stack: error.stack
            });
            throw error;
        }
    }

    // Execute a query and return the result metadata (useful for INSERT/UPDATE/DELETE)
    async run(text, params = []) {
        const start = Date.now();
        try {
            const result = await this.pool.query(text, params);
            const duration = Date.now() - start;
            
            if (process.env.NODE_ENV === 'development') {
                console.log('🔧 Command executed:', {
                    text: text.substring(0, 100) + '...',
                    duration: `${duration}ms`,
                    affected: result.rowCount
                });
            }
            
            return {
                rowCount: result.rowCount,
                insertId: result.rows[0]?.id || null, // For INSERT statements with RETURNING id
                changes: result.rowCount
            };
        } catch (error) {
            console.error('❌ Database command error:', {
                text: text.substring(0, 100) + '...',
                error: error.message
            });
            throw error;
        }
    }

    // Get a client from the pool for transactions
    async getClient() {
        try {
            const client = await this.pool.connect();
            return client;
        } catch (error) {
            console.error('❌ Error getting database client:', error);
            throw error;
        }
    }

    // Execute multiple queries in a transaction
    async transaction(callback) {
        const client = await this.getClient();
        try {
            await client.query('BEGIN');
            const result = await callback(client);
            await client.query('COMMIT');
            return result;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    // Check database connection
    async testConnection() {
        try {
            const result = await this.query('SELECT NOW() as current_time, version() as version');
            console.log('✅ PostgreSQL Connection successful:', {
                time: result[0].current_time,
                version: result[0].version.split(' ')[0] + ' ' + result[0].version.split(' ')[1]
            });
            return true;
        } catch (error) {
            console.error('❌ PostgreSQL Connection failed:', error.message);
            return false;
        }
    }

    // Get database statistics
    async getStats() {
        try {
            const queries = [
                { name: 'users', query: 'SELECT COUNT(*) as count FROM users' },
                { name: 'staff', query: 'SELECT COUNT(*) as count FROM admissions' },
                { name: 'active_sessions', query: 'SELECT COUNT(*) as count FROM user_sessions WHERE is_active = true AND expires_at > NOW()' },
                { name: 'login_attempts_today', query: 'SELECT COUNT(*) as count FROM login_attempts WHERE attempt_time >= CURRENT_DATE' },
                { name: 'database_size', query: "SELECT pg_size_pretty(pg_database_size(current_database())) as size" }
            ];

            const stats = {};
            for (const { name, query } of queries) {
                const result = await this.query(query);
                stats[name] = name === 'database_size' ? result[0].size : parseInt(result[0].count);
            }

            return stats;
        } catch (error) {
            console.error('❌ Error getting database stats:', error);
            return {};
        }
    }

    // Initialize database with schema (if needed)
    async initializeDatabase() {
        try {
            console.log('🔧 Checking database initialization...');
            
            // Check if users table exists
            const result = await this.query(`
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = 'users'
                )
            `);
            
            if (!result[0].exists) {
                console.log('📊 Database not initialized. Please run the SQL schema file first.');
                console.log('📁 Schema file: database/postgresql-enhanced-schema.sql');
                return false;
            }
            
            console.log('✅ Database already initialized');
            return true;
            
        } catch (error) {
            console.error('❌ Error checking database initialization:', error);
            return false;
        }
    }

    // Close all database connections
    async close() {
        try {
            await this.pool.end();
            console.log('🔌 PostgreSQL connections closed');
        } catch (error) {
            console.error('❌ Error closing database connections:', error);
        }
    }

    // Backup database (basic pg_dump command)
    getBackupCommand() {
        const config = this.pool.options;
        return `pg_dump -h ${config.host} -p ${config.port} -U ${config.user} -d ${config.database} --no-password > backup_$(date +%Y%m%d_%H%M%S).sql`;
    }

    // Health check for monitoring
    async healthCheck() {
        try {
            const start = Date.now();
            await this.query('SELECT 1');
            const responseTime = Date.now() - start;
            
            const stats = await this.getStats();
            
            return {
                status: 'healthy',
                database: 'postgresql',
                responseTime: `${responseTime}ms`,
                connections: {
                    total: this.pool.totalCount,
                    idle: this.pool.idleCount,
                    waiting: this.pool.waitingCount
                },
                stats: stats
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                error: error.message,
                database: 'postgresql'
            };
        }
    }
}

// Create and export database instance
const database = new PostgreSQLDatabase();

// Test connection on startup
database.testConnection().then(success => {
    if (success) {
        database.initializeDatabase();
    }
});

module.exports = database;