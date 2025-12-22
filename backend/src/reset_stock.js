const db = require('./db');

async function run() {
  try {
    await db.query('UPDATE products SET stock = 0');
    console.log('Stock reset to 0 for all products.');
  } catch (err) {
    console.error('Stock reset failed:', err);
    process.exitCode = 1;
  } finally {
    await db.pool.end();
  }
}

run();
