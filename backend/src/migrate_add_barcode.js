const db = require('./db');

async function run() {
  try {
    await db.query('BEGIN');
    await db.query(
      "ALTER TABLE customers ADD COLUMN IF NOT EXISTS barcode TEXT"
    );
    await db.query(
      "CREATE UNIQUE INDEX IF NOT EXISTS customers_barcode_key ON customers(barcode)"
    );
    await db.query('COMMIT');
    console.log('Customer barcode column ready.');
  } catch (err) {
    await db.query('ROLLBACK');
    console.error('Migration failed:', err);
    process.exitCode = 1;
  } finally {
    await db.pool.end();
  }
}

run();
