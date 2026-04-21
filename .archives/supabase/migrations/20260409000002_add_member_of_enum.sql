-- Add 'member_of' to product_relationship_type.
-- Must be its own migration so the value is committed before the lens-set
-- migrations (20260409000003–000005) attempt to use it.

ALTER TYPE product_relationship_type ADD VALUE IF NOT EXISTS 'member_of';
