-- Add sold_by and refund tracking columns to sales table
ALTER TABLE sales
  ADD COLUMN IF NOT EXISTS sold_by text NULL,
  ADD COLUMN IF NOT EXISTS refund_of text NULL,
  ADD COLUMN IF NOT EXISTS refund_reason text NULL;
