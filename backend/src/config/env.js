import 'dotenv/config';

const required = ['DATABASE_URL','JWT_SECRET'];
for (const key of required) if (!process.env[key]) throw new Error(`Missing env: ${key}`);
export const env = {
  port: Number(process.env.PORT || 3000),
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET,
  corsOrigin: process.env.CORS_ORIGIN || '*',
  digiflazz: {
    username: process.env.DIGIFLAZZ_USERNAME || '',
    apiKey: process.env.DIGIFLAZZ_API_KEY || '',
    baseUrl: process.env.DIGIFLAZZ_BASE_URL || 'https://api.digiflazz.com/v1',
    webhookSecret: process.env.DIGIFLAZZ_WEBHOOK_SECRET || ''
  }
};
