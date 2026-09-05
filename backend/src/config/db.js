import pg from 'pg';
import { env } from './env.js';
const { Pool } = pg;
export const pool = new Pool({ connectionString: env.databaseUrl, max: 20, idleTimeoutMillis: 30000 });
export const tx = async (fn) => { const c = await pool.connect(); try { await c.query('BEGIN'); const result = await fn(c); await c.query('COMMIT'); return result; } catch (e) { await c.query('ROLLBACK'); throw e; } finally { c.release(); } };
