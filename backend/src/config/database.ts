import sql from 'mssql/msnodesqlv8';
import { config } from './index';

// Build database config - Windows Authentication using connection string like Python
const buildDbConfig = (): any => {
  // Optimized pool settings
  const poolConfig = {
    max: 20,                    // Increased for high load
    min: 2,                     // Keep connections ready
    idleTimeoutMillis: 30000,
    acquireTimeoutMillis: 15000, // Timeout when acquiring
    createTimeoutMillis: 5000,   // Timeout when creating
  };

  // Windows Authentication - Trusted_Connection=yes
  if (config.db.useWindowsAuth) {
    const connectionString = `Driver={ODBC Driver 17 for SQL Server};Server=${config.db.server};Database=${config.db.database};Trusted_Connection=yes;`;

    return {
      connectionString,
      driver: 'msnodesqlv8',
      pool: poolConfig,
    };
  }

  // SQL Server Authentication
  return {
    server: config.db.server,
    port: config.db.port,
    database: config.db.database,
    user: config.db.user,
    password: config.db.password,
    options: {
      encrypt: config.db.options.encrypt,
      trustServerCertificate: config.db.options.trustServerCertificate,
    },
    pool: poolConfig,
  };
};

const dbConfig = buildDbConfig();

let pool: sql.ConnectionPool | null = null;

export const connectDB = async (): Promise<sql.ConnectionPool> => {
  try {
    if (pool) {
      return pool;
    }

    pool = await sql.connect(dbConfig);
    console.log('✅ Connected to SQL Server database');
    return pool;
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    throw error;
  }
};

export const getPool = (): sql.ConnectionPool => {
  if (!pool) {
    throw new Error('Database not connected. Call connectDB first.');
  }
  return pool;
};

export const closeDB = async (): Promise<void> => {
  if (pool) {
    await pool.close();
    pool = null;
    console.log('Database connection closed');
  }
};

export { sql };

