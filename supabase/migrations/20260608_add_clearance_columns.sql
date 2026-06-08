-- Add columns to persist clearance metadata for products
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS original_price numeric NULL,
  ADD COLUMN IF NOT EXISTS clearance_percent integer NULL;

-- Optional index for quick lookup by clearance
CREATE INDEX IF NOT EXISTS idx_products_clearance_percent ON products (clearance_percent);

-- Note: after running this migration, the UI will persist original_price and clearance_percent when applying clearance discounts.
