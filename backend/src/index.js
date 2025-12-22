require('dotenv').config();

const express = require('express');
const cors = require('cors');
const db = require('./db');

const app = express();
const port = process.env.PORT ? Number(process.env.PORT) : 3001;

app.use(cors());
app.use(express.json());

const CARD_NUMBER_MIN = 1;
const CARD_NUMBER_MAX = 128;

function mapProductRow(row) {
  return {
    name: row.name,
    category: row.category,
    pricePerUnit: Number(row.pricePerUnit ?? row.price_per_unit),
    unit: row.unit,
    purchasePrice: Number(row.purchasePrice ?? row.purchase_price),
    stock: Number(row.stock),
  };
}

function mapCustomerRow(row) {
  return {
    name: row.name,
    cardNumber: row.card_number,
    barcode: row.barcode,
    mobile: row.mobile,
    points: Number(row.points),
  };
}

function mapRedeemableRow(row) {
  return {
    name: row.name,
    pointsRequired: Number(row.points_required),
    stock: Number(row.stock),
  };
}

function mapNotificationRow(row) {
  return {
    id: Number(row.id),
    title: row.title,
    message: row.message,
    createdAt: row.created_at.toISOString(),
  };
}

async function loadSettings(client) {
  const { rows } = await client.query('SELECT key, value FROM settings');
  const settings = {
    petrol: 1,
    diesel: 1,
    oil: 2,
    amount: 10,
  };
  for (const row of rows) {
    settings[row.key] = Number(row.value);
  }
  return settings;
}

function normalizeCardNumber(input) {
  if (typeof input !== 'string') {
    throw new Error('cardNumber must be a string');
  }
  const trimmed = input.trim();
  if (trimmed.length < CARD_NUMBER_MIN || trimmed.length > CARD_NUMBER_MAX) {
    throw new Error(`cardNumber must be ${CARD_NUMBER_MIN}-${CARD_NUMBER_MAX} characters`);
  }
  return trimmed;
}

function normalizeMobile(input) {
  if (input == null || input === '') return '';
  if (typeof input !== 'string') {
    throw new Error('mobile must be a string');
  }
  const trimmed = input.trim();
  if (!/^[0-9+ -]+$/.test(trimmed)) {
    throw new Error('mobile must be digits');
  }
  if (trimmed.length < 8 || trimmed.length > 15) {
    throw new Error('mobile must be 8-15 characters');
  }
  return trimmed;
}

function normalizeBarcode(input) {
  if (input == null || input === '') return null;
  if (typeof input !== 'string') {
    throw new Error('barcode must be a string');
  }
  const trimmed = input.trim();
  if (trimmed.length < 1 || trimmed.length > 128) {
    throw new Error('barcode must be 1-128 characters');
  }
  return trimmed;
}

function deriveCategoryFromName(name) {
  const normalized = String(name || '').toLowerCase();
  if (normalized.includes('petrol') || normalized.includes('diesel')) {
    return 'Fuel';
  }
  if (normalized.includes('coolant')) {
    return 'Coolant';
  }
  if (normalized.includes('oil')) {
    return 'Oil';
  }
  return 'Other';
}

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/api/products', async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT name, category, price_per_unit, unit, purchase_price, stock FROM products ORDER BY name'
    );
    res.json({ products: rows.map(mapProductRow) });
  } catch (err) {
    console.error('GET /api/products failed:', err);
    res.status(500).json({ error: 'Failed to load products' });
  }
});

app.put('/api/products', async (req, res) => {
  const payload = req.body?.products;
  if (!Array.isArray(payload)) {
    return res.status(400).json({ error: 'products must be an array' });
  }

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');
    for (const item of payload) {
      if (!item?.name) {
        throw new Error('Product name is required');
      }
      const category = item.category || item.productCategory || deriveCategoryFromName(item.name);
      await client.query(
        `INSERT INTO products (name, category, price_per_unit, unit, purchase_price, stock)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (name) DO UPDATE SET
           category = EXCLUDED.category,
           price_per_unit = EXCLUDED.price_per_unit,
           unit = EXCLUDED.unit,
           purchase_price = EXCLUDED.purchase_price,
           stock = EXCLUDED.stock`,
        [
          item.name,
          category,
          Number(item.pricePerUnit ?? item.price_per_unit ?? 0),
          item.unit || 'L',
          Number(item.purchasePrice ?? item.purchase_price ?? 0),
          Number(item.stock ?? 0),
        ]
      );
    }
    const { rows } = await client.query(
      'SELECT name, category, price_per_unit, unit, purchase_price, stock FROM products ORDER BY name'
    );
    await client.query('COMMIT');
    res.json({ products: rows.map(mapProductRow) });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('PUT /api/products failed:', err);
    res.status(400).json({ error: err.message || 'Failed to save products' });
  } finally {
    client.release();
  }
});

app.get('/api/bootstrap', async (req, res) => {
  try {
    const [productsResult, customersResult, redeemablesResult, settingsResult, salesResult, notificationsResult] =
      await Promise.all([
        db.query('SELECT name, category, price_per_unit, unit, purchase_price, stock FROM products ORDER BY name'),
        db.query('SELECT name, card_number, barcode, mobile, points FROM customers ORDER BY name'),
        db.query('SELECT name, points_required, stock FROM redeemable_products ORDER BY name'),
        db.query('SELECT key, value FROM settings'),
        db.query(
          `SELECT
             s.units,
             s.amount,
             s.purchase_cost,
             s.profit,
             s.points_earned,
             s.created_at,
             p.name AS product,
             COALESCE(c.name, 'Walk-in Customer') AS customer
           FROM sales s
           JOIN products p ON s.product_id = p.id
           LEFT JOIN customers c ON s.customer_id = c.id
           ORDER BY s.created_at DESC`
        ),
        db.query('SELECT id, title, message, created_at FROM push_notifications ORDER BY created_at DESC'),
      ]);

    const settings = {
      petrol: 1,
      diesel: 1,
      oil: 2,
      amount: 10,
    };
    for (const row of settingsResult.rows) {
      settings[row.key] = Number(row.value);
    }

    const sales = salesResult.rows.map((row) => ({
      product: row.product,
      units: Number(row.units),
      amount: Number(row.amount),
      purchaseCost: Number(row.purchase_cost),
      customer: row.customer,
      date: row.created_at.toISOString(),
      pointsEarned: Number(row.points_earned),
      profit: Number(row.profit),
    }));

    res.json({
      products: productsResult.rows.map(mapProductRow),
      customers: customersResult.rows.map(mapCustomerRow),
      redeemables: redeemablesResult.rows.map(mapRedeemableRow),
      settings,
      sales,
      notifications: notificationsResult.rows.map(mapNotificationRow),
    });
  } catch (err) {
    console.error('GET /api/bootstrap failed:', err);
    res.status(500).json({ error: 'Failed to load bootstrap data' });
  }
});

app.post('/api/customers', async (req, res) => {
  const { name, cardNumber, mobile, barcode } = req.body || {};
  if (!name || !cardNumber) {
    return res.status(400).json({ error: 'name and cardNumber are required' });
  }

  try {
    const normalizedCard = normalizeCardNumber(cardNumber);
    const normalizedMobile = normalizeMobile(mobile);
    const normalizedBarcode = normalizeBarcode(barcode);

    const existing = await db.query(
      'SELECT name, card_number, barcode, mobile, points FROM customers WHERE card_number = $1',
      [normalizedCard]
    );
    if (existing.rowCount > 0) {
      return res.status(409).json({ error: 'cardNumber already exists' });
    }

    if (normalizedBarcode) {
      const barcodeExists = await db.query(
        'SELECT id FROM customers WHERE barcode = $1',
        [normalizedBarcode]
      );
      if (barcodeExists.rowCount > 0) {
        return res.status(409).json({ error: 'barcode already exists' });
      }
    }

    const { rows } = await db.query(
      `INSERT INTO customers (name, card_number, barcode, mobile, points)
       VALUES ($1, $2, $3, $4, 0)
       RETURNING name, card_number, barcode, mobile, points`,
      [name, normalizedCard, normalizedBarcode, normalizedMobile]
    );

    res.json({ customer: mapCustomerRow(rows[0]) });
  } catch (err) {
    console.error('POST /api/customers failed:', err);
    res.status(400).json({ error: err.message || 'Failed to add customer' });
  }
});

app.get('/api/customers', async (req, res) => {
  const { cardNumber, barcode } = req.query || {};
  if (!cardNumber && !barcode) {
    return res.status(400).json({ error: 'cardNumber or barcode query param is required' });
  }
  try {
    let rows = [];
    if (cardNumber) {
      const normalizedCard = normalizeCardNumber(String(cardNumber));
      const result = await db.query(
        'SELECT name, card_number, barcode, mobile, points FROM customers WHERE card_number = $1',
        [normalizedCard]
      );
      rows = result.rows;
    } else if (barcode) {
      const normalizedBarcode = normalizeBarcode(String(barcode));
      const result = await db.query(
        'SELECT name, card_number, barcode, mobile, points FROM customers WHERE barcode = $1',
        [normalizedBarcode]
      );
      rows = result.rows;
    }
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Customer not found' });
    }
    return res.json({ customer: mapCustomerRow(rows[0]) });
  } catch (err) {
    console.error('GET /api/customers failed:', err);
    return res.status(400).json({ error: err.message || 'Invalid card number' });
  }
});

app.get('/api/customers/:cardNumber', async (req, res) => {
  try {
    const normalizedCard = normalizeCardNumber(req.params.cardNumber);
    const { rows } = await db.query(
      'SELECT name, card_number, barcode, mobile, points FROM customers WHERE card_number = $1',
      [normalizedCard]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Customer not found' });
    }
    return res.json({ customer: mapCustomerRow(rows[0]) });
  } catch (err) {
    console.error('GET /api/customers/:cardNumber failed:', err);
    return res.status(400).json({ error: err.message || 'Invalid card number' });
  }
});

app.post('/api/sales', async (req, res) => {
  const { product, units, amount, customerCardNumber } = req.body || {};
  if (!product || !units || !amount) {
    return res.status(400).json({ error: 'product, units and amount are required' });
  }

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');

    const productResult = await client.query(
      'SELECT id, name, price_per_unit, purchase_price, stock, unit FROM products WHERE name = $1',
      [product]
    );
    if (productResult.rowCount === 0) {
      throw new Error('Product not found');
    }

    const productRow = productResult.rows[0];
    const availableStock = Number(productRow.stock);
    const unitsInt = Number(units);
    const amountNum = Number(amount);

    if (unitsInt <= 0) {
      throw new Error('Units must be greater than 0');
    }

    if (unitsInt > availableStock) {
      throw new Error('Insufficient stock');
    }

    const settings = await loadSettings(client);
    let pointsEarned = 0;
    if (productRow.name === 'Petrol') {
      pointsEarned = unitsInt * settings.petrol;
    } else if (productRow.name === 'Diesel') {
      pointsEarned = unitsInt * settings.diesel;
    } else {
      pointsEarned = unitsInt * settings.oil;
    }
    pointsEarned += Math.floor(amountNum / settings.amount);

    const purchaseCost = unitsInt * Number(productRow.purchase_price);
    const profit = amountNum - purchaseCost;

    let customerRow = null;
    if (customerCardNumber) {
      const normalizedCard = normalizeCardNumber(customerCardNumber);
      const customerResult = await client.query(
        'SELECT id, name, card_number, mobile, points FROM customers WHERE card_number = $1',
        [normalizedCard]
      );
      if (customerResult.rowCount === 0) {
        throw new Error('Customer not found');
      }
      customerRow = customerResult.rows[0];

      const updatedPoints = Number(customerRow.points) + pointsEarned;
      const updatedCustomer = await client.query(
        'UPDATE customers SET points = $1 WHERE id = $2 RETURNING name, card_number, mobile, points',
        [updatedPoints, customerRow.id]
      );
      customerRow = updatedCustomer.rows[0];
    }

    const updatedStock = availableStock - unitsInt;
    const updatedProductResult = await client.query(
      'UPDATE products SET stock = $1 WHERE id = $2 RETURNING name, price_per_unit, unit, purchase_price, stock',
      [updatedStock, productRow.id]
    );

    const saleInsert = await client.query(
      `INSERT INTO sales (product_id, customer_id, units, amount, purchase_cost, profit, points_earned)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, units, amount, purchase_cost, profit, points_earned, created_at`,
      [
        productRow.id,
        customerRow ? customerRow.id : null,
        unitsInt,
        amountNum,
        purchaseCost,
        profit,
        pointsEarned,
      ]
    );

    await client.query('COMMIT');

    const saleRow = saleInsert.rows[0];
    res.json({
      sale: {
        product: productRow.name,
        units: Number(saleRow.units),
        amount: Number(saleRow.amount),
        purchaseCost: Number(saleRow.purchase_cost),
        customer: customerRow ? customerRow.name : 'Walk-in Customer',
        date: saleRow.created_at.toISOString(),
        pointsEarned: Number(saleRow.points_earned),
        profit: Number(saleRow.profit),
      },
      product: mapProductRow(updatedProductResult.rows[0]),
      customer: customerRow ? mapCustomerRow(customerRow) : null,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('POST /api/sales failed:', err);
    res.status(400).json({ error: err.message || 'Failed to record sale' });
  } finally {
    client.release();
  }
});

app.put('/api/settings/points', async (req, res) => {
  const { petrol, diesel, oil, amount } = req.body || {};
  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');
    const entries = [
      ['petrol', petrol],
      ['diesel', diesel],
      ['oil', oil],
      ['amount', amount],
    ];
    for (const [key, value] of entries) {
      if (typeof value !== 'number' || Number.isNaN(value)) {
        throw new Error(`Invalid value for ${key}`);
      }
      await client.query(
        `INSERT INTO settings (key, value)
         VALUES ($1, $2)
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value`,
        [key, value]
      );
    }
    await client.query('COMMIT');
    res.json({ success: true });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('PUT /api/settings/points failed:', err);
    res.status(400).json({ error: err.message || 'Failed to save settings' });
  } finally {
    client.release();
  }
});

app.post('/api/redemptions', async (req, res) => {
  const { customerCardNumber, items } = req.body || {};
  if (!customerCardNumber || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'customerCardNumber and items are required' });
  }

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');

    const normalizedCard = normalizeCardNumber(customerCardNumber);
    const customerResult = await client.query(
      'SELECT id, name, card_number, mobile, points FROM customers WHERE card_number = $1',
      [normalizedCard]
    );
    if (customerResult.rowCount === 0) {
      throw new Error('Customer not found');
    }
    const customerRow = customerResult.rows[0];

    const redeemableRows = [];
    let totalPoints = 0;

    for (const item of items) {
      if (!item?.product || !item?.quantity) {
        throw new Error('Invalid redemption item');
      }

      const productResult = await client.query(
        'SELECT id, name, points_required, stock FROM redeemable_products WHERE name = $1',
        [item.product]
      );
      if (productResult.rowCount === 0) {
        throw new Error(`Redeemable not found: ${item.product}`);
      }

      const redeemable = productResult.rows[0];
      const quantityInt = Number(item.quantity);
      if (quantityInt <= 0) {
        throw new Error('Quantity must be greater than 0');
      }
      if (quantityInt > Number(redeemable.stock)) {
        throw new Error(`Insufficient stock for ${redeemable.name}`);
      }

      totalPoints += quantityInt * Number(redeemable.points_required);
      redeemableRows.push({ redeemable, quantity: quantityInt });
    }

    if (Number(customerRow.points) < totalPoints) {
      throw new Error('Insufficient points');
    }

    const updatedPoints = Number(customerRow.points) - totalPoints;
    const updatedCustomerResult = await client.query(
      'UPDATE customers SET points = $1 WHERE id = $2 RETURNING name, card_number, mobile, points',
      [updatedPoints, customerRow.id]
    );

    const redemptionInsert = await client.query(
      'INSERT INTO redemptions (customer_id, points_spent) VALUES ($1, $2) RETURNING id',
      [customerRow.id, totalPoints]
    );

    const redemptionId = redemptionInsert.rows[0].id;

    for (const item of redeemableRows) {
      const updatedStock = Number(item.redeemable.stock) - item.quantity;
      await client.query(
        'UPDATE redeemable_products SET stock = $1 WHERE id = $2',
        [updatedStock, item.redeemable.id]
      );
      await client.query(
        'INSERT INTO redemption_items (redemption_id, redeemable_product_id, quantity) VALUES ($1, $2, $3)',
        [redemptionId, item.redeemable.id, item.quantity]
      );
    }

    const updatedRedeemables = await client.query(
      'SELECT name, points_required, stock FROM redeemable_products ORDER BY name'
    );

    await client.query('COMMIT');

    res.json({
      customer: mapCustomerRow(updatedCustomerResult.rows[0]),
      products: updatedRedeemables.rows.map(mapRedeemableRow),
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('POST /api/redemptions failed:', err);
    res.status(400).json({ error: err.message || 'Failed to redeem points' });
  } finally {
    client.release();
  }
});

app.get('/api/notifications', async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT id, title, message, created_at FROM push_notifications ORDER BY created_at DESC'
    );
    res.json({ notifications: rows.map(mapNotificationRow) });
  } catch (err) {
    console.error('GET /api/notifications failed:', err);
    res.status(500).json({ error: 'Failed to load notifications' });
  }
});

app.post('/api/notifications', async (req, res) => {
  const { title, message } = req.body || {};
  if (!title || !message) {
    return res.status(400).json({ error: 'title and message are required' });
  }
  try {
    const { rows } = await db.query(
      'INSERT INTO push_notifications (title, message) VALUES ($1, $2) RETURNING id, title, message, created_at',
      [title, message]
    );
    res.json({ notification: mapNotificationRow(rows[0]) });
  } catch (err) {
    console.error('POST /api/notifications failed:', err);
    res.status(500).json({ error: 'Failed to create notification' });
  }
});

app.delete('/api/notifications/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) {
    return res.status(400).json({ error: 'Invalid id' });
  }
  try {
    await db.query('DELETE FROM push_notifications WHERE id = $1', [id]);
    res.json({ success: true });
  } catch (err) {
    console.error('DELETE /api/notifications failed:', err);
    res.status(500).json({ error: 'Failed to delete notification' });
  }
});

app.listen(port, () => {
  console.log(`Backend running on http://localhost:${port}`);
});
