const db = require('./db');

async function run() {
  try {
    await db.query('BEGIN');
    await db.query('DELETE FROM redemption_items');
    await db.query('DELETE FROM redemptions');
    await db.query('DELETE FROM sales');
    await db.query('DELETE FROM customers');
    await db.query('DELETE FROM redeemable_products');
    await db.query('DELETE FROM push_notifications');
    await db.query('COMMIT');
    console.log('Demo data removed.');
  } catch (err) {
    await db.query('ROLLBACK');
    console.error('Cleanup failed:', err);
    process.exitCode = 1;
  } finally {
    await db.pool.end();
  }
}

run();
