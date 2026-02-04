import dotenv from 'dotenv';
dotenv.config();

// Validate critical environment variables
const getJwtSecret = (): string => {
  const secret = process.env.JWT_SECRET;
  if (!secret && process.env.NODE_ENV === 'production') {
    throw new Error('JWT_SECRET environment variable must be set in production!');
  }
  return secret || 'dev_secret_do_not_use_in_production';
};

const getCorsOrigin = (): string | string[] => {
  const origin = process.env.CORS_ORIGIN;
  if (!origin && process.env.NODE_ENV === 'production') {
    throw new Error('CORS_ORIGIN must be set in production!');
  }
  // In development, allow all origins
  if (!origin || origin === '*') {
    return process.env.NODE_ENV === 'production'
      ? ['https://healthcare.com'] // Default production domain
      : '*';
  }
  // Support comma-separated origins
  return origin.includes(',') ? origin.split(',').map(o => o.trim()) : origin;
};

export const config = {
  // Server
  port: parseInt(process.env.PORT || '5000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',

  // Database
  db: {
    server: process.env.DB_SERVER || 'localhost',
    port: parseInt(process.env.DB_PORT || '1433', 10),
    database: process.env.DB_DATABASE || 'HeathCare',
    user: process.env.DB_USER || '',
    password: process.env.DB_PASSWORD || '',
    // Windows Authentication - set to 'true' to use
    useWindowsAuth: process.env.DB_USE_WINDOWS_AUTH === 'true',
    options: {
      encrypt: process.env.DB_ENCRYPT === 'true',
      trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE !== 'false',
    },
  },

  // JWT - Throws error in production if not set
  jwt: {
    secret: getJwtSecret(),
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },

  // CORS - Throws error in production if not set
  corsOrigin: getCorsOrigin(),
};


