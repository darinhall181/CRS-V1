-- ─────────────────────────────────────────────────────────────────────────────
-- Sections 2 & 3: Seed all brands for the 80/20 cinema equipment reference.
-- Covers camera, lens, accessory, and rental house manufacturers.
-- ON CONFLICT DO NOTHING — safe to re-run.
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO brand (name, slug, website_url, scraping_enabled) VALUES

  -- ── Camera brands ──────────────────────────────────────────────────────────
  -- ARRI and Sony already seeded — guarded by ON CONFLICT
  ('ARRI',              'arri',       'https://www.arri.com',                  true),
  ('Sony',              'sony',       'https://pro.sony/ue_US',                true),
  ('Canon',             'canon',      'https://www.usa.canon.com',             true),
  ('RED (Nikon)',        'red',        'https://www.red.com',                   true),
  ('Blackmagic Design', 'blackmagic', 'https://www.blackmagicdesign.com',      true),

  -- ── Cinema lens brands ─────────────────────────────────────────────────────
  ('Cooke Optics',      'cooke',      'https://www.cookeoptics.com',           true),
  ('Carl Zeiss AG',     'zeiss',      'https://www.zeiss.com/consumer-products/us/cinematography', true),
  ('Angenieux',         'angenieux',  'https://www.angenieux.com',             true),
  ('Sigma',             'sigma',      'https://www.sigmaphoto.com',            true),
  ('Leica / Leitz Cine','leica-cine', 'https://www.leica-camera.com/en-US/leica-cine', true),

  -- ── Monitor brands ─────────────────────────────────────────────────────────
  ('SmallHD',           'smallhd',    'https://smallhd.com',                   true),
  ('Atomos',            'atomos',     'https://www.atomos.com',                true),

  -- ── Wireless video ─────────────────────────────────────────────────────────
  ('Teradek',           'teradek',    'https://teradek.com',                   true),

  -- ── Follow focus / FIZ ─────────────────────────────────────────────────────
  ('Preston Cinema',    'preston',    'https://www.prestoncinema.com',         false),
  ('Tilta',             'tilta',      'https://tilta.com',                     true),
  ('cmotion',           'cmotion',    'https://www.cmotion.eu/en',             false),

  -- ── Matte boxes & rigging ──────────────────────────────────────────────────
  ('Bright Tangerine',  'bright-tangerine', 'https://brighttangerine.com',     true),
  ('Wooden Camera',     'wooden-camera',    'https://woodencamera.com',        true),

  -- ── Power & batteries ──────────────────────────────────────────────────────
  ('Anton Bauer',       'anton-bauer','https://www.antonbauer.com',            false),
  ('Core SWX',          'core-swx',   'https://www.coreswx.com',              false),
  ('IDX',               'idx',        'https://www.idx.co.jp',                false),

  -- ── Camera support ─────────────────────────────────────────────────────────
  ('OConnor',           'oconnor',    'https://www.ocon.com',                  false),
  ('Sachtler',          'sachtler',   'https://www.sachtler.com',              false)

ON CONFLICT DO NOTHING;
