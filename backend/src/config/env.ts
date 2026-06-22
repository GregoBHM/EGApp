import dotenv from 'dotenv';

dotenv.config();

function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`[Config] Variable de entorno requerida no encontrada: ${key}`);
  }
  return value;
}

export const env = {
  port: parseInt(process.env.PORT ?? '3000', 10),
  nodeEnv: process.env.NODE_ENV ?? 'development',

  firebase: {
    projectId: requireEnv('FIREBASE_PROJECT_ID'),
    clientEmail: requireEnv('FIREBASE_CLIENT_EMAIL'),
    privateKey: requireEnv('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n'),
    storageBucket: requireEnv('FIREBASE_STORAGE_BUCKET'),
  },

  encryption: {
    masterKey: requireEnv('ENCRYPTION_MASTER_KEY'),
  },

  redis: {
    host: process.env.REDIS_HOST ?? '127.0.0.1',
    port: parseInt(process.env.REDIS_PORT ?? '6379', 10),
  },

  sunat: {
    apiBaseUrl: requireEnv('SUNAT_API_BASE_URL'),
    tokenUrl: requireEnv('SUNAT_TOKEN_URL'),
    gemUrl: requireEnv('SUNAT_GEM_URL'),
    portalUrl: requireEnv('SUNAT_PORTAL_URL'),
  },

  playwright: {
    headless: process.env.PLAYWRIGHT_HEADLESS !== 'false',
  },
};
