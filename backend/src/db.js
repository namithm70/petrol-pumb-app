const { Pool } = require('pg');

const hasDatabaseUrl = Boolean(process.env.DATABASE_URL);

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  host: hasDatabaseUrl ? undefined : process.env.PGHOST || 'localhost',
  port: hasDatabaseUrl ? undefined : process.env.PGPORT ? Number(process.env.PGPORT) : 5432,
  user: hasDatabaseUrl ? undefined : process.env.PGUSER || 'postgres',
  password: hasDatabaseUrl ? undefined : process.env.PGPASSWORD || 'postgres',
  database: hasDatabaseUrl ? undefined : process.env.PGDATABASE || 'bpclpos',
  ssl: hasDatabaseUrl ? { rejectUnauthorized: false } : undefined,
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
