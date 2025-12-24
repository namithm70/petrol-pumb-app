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

INSERT INTO customers (name, card_number, barcode, mobile, points) VALUES
  ('Rajesh Kumar', '4111111111111111', '4111111111111111', '9876543210', 1250),
  ('Priya Sharma', '5555555555554444', '5555555555554444', '8765432109', 850),
  ('Amit Patel', '378282246310005', '378282246310005', '7654321098', 2100),
  ('Sneha Reddy', '6011111111111117', '6011111111111117', '6543210987', 450),
  ('Vikram Singh', '3530111333300000', '3530111333300000', '9432109876', 1800)
ON CONFLICT (card_number) DO UPDATE SET
  name = EXCLUDED.name,
  barcode = EXCLUDED.barcode,
  mobile = EXCLUDED.mobile,
  points = EXCLUDED.points;

INSERT INTO redeemable_products (name, points_required, stock) VALUES
  ('Coffee 500g', 250, 30),
  ('Tea Bag 100pcs', 150, 50),
  ('Energy Drink', 100, 40),
  ('Snack Pack', 80, 60),
  ('Water Bottle', 120, 25),
  ('Air Freshener', 90, 35),
  ('Premium Pen Set', 200, 20),
  ('Charger Cable', 300, 15),
  ('Phone Stand', 180, 10),
  ('Sunscreen 100ml', 220, 12)
ON CONFLICT (name) DO UPDATE SET
  points_required = EXCLUDED.points_required,
  stock = EXCLUDED.stock;

INSERT INTO settings (key, value) VALUES
  ('petrol', 1),
  ('diesel', 1),
  ('oil', 2),
  ('amount', 10)
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value;

-- Optional starter notifications (empty by default)
