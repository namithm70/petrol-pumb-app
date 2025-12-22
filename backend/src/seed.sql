INSERT INTO products (name, category, price_per_unit, unit, purchase_price, stock) VALUES
  ('Petrol', 'Fuel', 100.00, 'L', 90.00, 0),
  ('Diesel', 'Fuel', 90.00, 'L', 80.00, 0),
  ('Engine Oil', 'Oil', 500.00, 'L', 400.00, 0),
  ('Gear Oil', 'Oil', 450.00, 'L', 350.00, 0),
  ('Brake Oil', 'Oil', 300.00, 'L', 250.00, 0),
  ('Coolant', 'Coolant', 250.00, 'L', 200.00, 0)
ON CONFLICT (name) DO UPDATE SET
  category = EXCLUDED.category,
  price_per_unit = EXCLUDED.price_per_unit,
  unit = EXCLUDED.unit,
  purchase_price = EXCLUDED.purchase_price,
  stock = EXCLUDED.stock;

INSERT INTO settings (key, value) VALUES
  ('petrol', 1),
  ('diesel', 1),
  ('oil', 2),
  ('amount', 10)
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value;

-- Optional starter notifications (empty by default)
