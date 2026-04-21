-- Move Canon cinema lenses (CN-E primes, CN-R primes, Cine Servo zooms)
-- from the generic 'lenses' category to 'cinema-lenses'.
--
-- These products were scraped when Canon's discovery ran over the full
-- lens catalogue, which placed every lens under the generic 'lenses' slug.
-- Correct category is 'cinema-lenses' alongside the Zeiss primes.
--
-- Safe to re-run (UPDATE only touches rows that still have the wrong category).

DO $$
DECLARE
  lenses_id        UUID;
  cinema_lenses_id UUID;
BEGIN
  SELECT id INTO lenses_id        FROM product_category WHERE slug = 'lenses';
  SELECT id INTO cinema_lenses_id FROM product_category WHERE slug = 'cinema-lenses';

  IF lenses_id IS NULL THEN
    RAISE EXCEPTION 'category lenses not found';
  END IF;
  IF cinema_lenses_id IS NULL THEN
    RAISE EXCEPTION 'category cinema-lenses not found';
  END IF;

  -- CN-E prime lenses (EF / PL mount cinema primes)
  UPDATE product
  SET category_id = cinema_lenses_id, updated_at = NOW()
  WHERE category_id = lenses_id
    AND slug LIKE 'cn-e%';

  -- CN-R prime lenses (RF mount cinema primes)
  UPDATE product
  SET category_id = cinema_lenses_id, updated_at = NOW()
  WHERE category_id = lenses_id
    AND slug LIKE 'cn-r%';

  -- Cine Servo zoom lenses
  UPDATE product
  SET category_id = cinema_lenses_id, updated_at = NOW()
  WHERE category_id = lenses_id
    AND slug LIKE 'cine-servo%';

  RAISE NOTICE 'Done. Moved CN-E, CN-R, and Cine Servo lenses to cinema-lenses.';
END $$;
