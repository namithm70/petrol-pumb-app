const fs = require('fs');
const path = require('path');
const db = require('./db');

async function run() {
  const schemaPath = path.join(__dirname, 'schema.sql');
  const seedPath = path.join(__dirname, 'seed.sql');
  const schemaSql = fs.readFileSync(schemaPath, 'utf8');
  const seedSql = fs.readFileSync(seedPath, 'utf8');

  try {
    await db.query('BEGIN');
    await db.query(schemaSql);
    await db.query(seedSql);
    await db.query('COMMIT');
    console.log('Database initialized.');
  } catch (err) {
    await db.query('ROLLBACK');
    console.error('Database init failed:', err);
    process.exitCode = 1;
  } finally {
    await db.pool.end();
  }
}

run();
