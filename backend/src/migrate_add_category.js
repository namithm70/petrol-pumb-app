const db = require('./db');

async function run() {
  try {
    await db.query('BEGIN');
    await db.query(
      "ALTER TABLE products ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'Other'"
    );
    await db.query(
      `UPDATE products
       SET category = CASE
         WHEN LOWER(name) LIKE '%petrol%' THEN 'Fuel'
         WHEN LOWER(name) LIKE '%diesel%' THEN 'Fuel'
         WHEN LOWER(name) LIKE '%coolant%' THEN 'Coolant'
         WHEN LOWER(name) LIKE '%oil%' THEN 'Oil'
         ELSE 'Other'
       END`
    );
    await db.query('COMMIT');
    console.log('Product categories migrated.');
  } catch (err) {
    await db.query('ROLLBACK');
    console.error('Migration failed:', err);
    process.exitCode = 1;
  } finally {
    await db.pool.end();
  }
}

run();
