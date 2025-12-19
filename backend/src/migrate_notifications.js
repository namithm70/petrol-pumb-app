const db = require('./db');

async function run() {
  try {
    await db.query('BEGIN');
    await db.query(
      `CREATE TABLE IF NOT EXISTS push_notifications (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )`
    );
    await db.query('COMMIT');
    console.log('Notifications table ready.');
  } catch (err) {
    await db.query('ROLLBACK');
    console.error('Migration failed:', err);
    process.exitCode = 1;
  } finally {
    await db.pool.end();
  }
}

run();
