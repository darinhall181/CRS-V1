-- Migration: Ohio rental houses — sourced from ohio_rental_houses.csv in repo root.
--
-- Inserts 13 rental houses (14 CSV rows — Liminal Space deduped into 1 house
-- with 2 locations). Street addresses stored in description; contact emails
-- are not in the schema so are omitted.
--
-- Type assignments:
--   full_service  — primary cinema/broadcast rental inventory
--   specialty     — camera stores, photo-focused, studio-first businesses
--
-- Safe to re-run: all inserts use ON CONFLICT DO NOTHING.

DO $$
DECLARE
  rh_ohio_cinemotion     UUID;
  rh_cleveland_camera    UUID;
  rh_dodd                UUID;
  rh_liminal             UUID;
  rh_osv                 UUID;
  rh_mpex                UUID;
  rh_cencam              UUID;
  rh_kinopicz            UUID;
  rh_ohd                 UUID;
  rh_allprohd            UUID;
  rh_procam              UUID;
  rh_akron               UUID;
  rh_campus              UUID;
BEGIN

  -- ── Insert rental houses ──────────────────────────────────────────────────

  INSERT INTO rental_house (name, slug, website_url, type, description, is_active) VALUES
    ('Ohio CineMotion',
     'ohio-cinemotion',
     'https://www.ohiocinemotion.com',
     'full_service',
     '1 American Road, Suite 700-A, Cleveland, OH — Contact: william@ohiocinemotion.com',
     true),

    ('Cleveland Camera Rental',
     'cleveland-camera-rental',
     'https://www.clevelandcamerarental.com',
     'full_service',
     '1419 E 40th St, Cleveland, OH — Contact: support@clevelandcamerarental.com',
     true),

    ('Dodd Camera Professional',
     'dodd-camera',
     'https://doddpro.com',
     'specialty',
     '2077 East 30th St, Cleveland, OH — Contact: estore@doddcamera.com',
     true),

    ('Liminal Space Rentals',
     'liminal-space-rentals',
     'https://liminalspaceproductions.com',
     'full_service',
     'Multi-location rental operation (Cleveland & Columbus). Contact: rent@liminalspaceproductions.com',
     true),

    ('OSV Studios',
     'osv-studios',
     'https://www.osvstudios.com',
     'specialty',
     '29605 Lorain Rd, North Olmsted, OH — Contact: csmith@osvstudios.com',
     true),

    ('Midwest Photo Rentals (MPEX)',
     'midwest-photo-rentals',
     'https://www.mpexrentals.com',
     'specialty',
     '2887 Silver Drive, Columbus, OH — Contact: rentals@mpex.com',
     true),

    ('CENCAM',
     'cencam',
     'https://cencam.com',
     'full_service',
     '1166 Cleveland Ave, Columbus, OH',
     true),

    ('Kinopicz American',
     'kinopicz-american',
     'https://kinopicz.com',
     'full_service',
     '1217 Goodale Blvd, Columbus, OH — Contact: hello@kinopicz.com',
     true),

    ('OHD Studios',
     'ohd-studios',
     'https://www.ohdstudios.com',
     'specialty',
     '350 W Johnstown Rd, Columbus, OH — Contact: info@ohdstudios.com',
     true),

    ('AllProHD',
     'allprohd',
     'https://allprohd.com',
     'full_service',
     '2900 Park Avenue West, Ontario, OH',
     true),

    ('PROCAM Rentals Cincinnati',
     'procam-cincinnati',
     'https://procam.com/pages/rentals-cincinnati',
     'full_service',
     '1014 Ohio Pike, Cincinnati, OH — Contact: cincinnati@procam.com',
     true),

    ('Akron Studio Rentals',
     'akron-studio-rentals',
     'https://akronstudiorentals.com',
     'specialty',
     'Akron, OH',
     true),

    ('Campus Camera & Imaging',
     'campus-camera',
     'https://www.campuscamera.net',
     'specialty',
     '1645 E. Main Street, Kent, OH — Contact: CampusCameraLab@hotmail.com',
     true)

  ON CONFLICT (slug) DO NOTHING;

  -- ── Capture IDs for location rows ─────────────────────────────────────────

  SELECT id INTO rh_ohio_cinemotion  FROM rental_house WHERE slug = 'ohio-cinemotion';
  SELECT id INTO rh_cleveland_camera FROM rental_house WHERE slug = 'cleveland-camera-rental';
  SELECT id INTO rh_dodd             FROM rental_house WHERE slug = 'dodd-camera';
  SELECT id INTO rh_liminal          FROM rental_house WHERE slug = 'liminal-space-rentals';
  SELECT id INTO rh_osv              FROM rental_house WHERE slug = 'osv-studios';
  SELECT id INTO rh_mpex             FROM rental_house WHERE slug = 'midwest-photo-rentals';
  SELECT id INTO rh_cencam           FROM rental_house WHERE slug = 'cencam';
  SELECT id INTO rh_kinopicz         FROM rental_house WHERE slug = 'kinopicz-american';
  SELECT id INTO rh_ohd              FROM rental_house WHERE slug = 'ohd-studios';
  SELECT id INTO rh_allprohd         FROM rental_house WHERE slug = 'allprohd';
  SELECT id INTO rh_procam           FROM rental_house WHERE slug = 'procam-cincinnati';
  SELECT id INTO rh_akron            FROM rental_house WHERE slug = 'akron-studio-rentals';
  SELECT id INTO rh_campus           FROM rental_house WHERE slug = 'campus-camera';

  -- ── Insert locations ───────────────────────────────────────────────────────

  INSERT INTO rental_house_location (rental_house_id, city, state_or_region, country) VALUES
    (rh_ohio_cinemotion,  'Cleveland',     'OH', 'US'),
    (rh_cleveland_camera, 'Cleveland',     'OH', 'US'),
    (rh_dodd,             'Cleveland',     'OH', 'US'),
    -- Liminal Space: two locations, same company
    (rh_liminal,          'Cleveland',     'OH', 'US'),
    (rh_liminal,          'Columbus',      'OH', 'US'),
    (rh_osv,              'North Olmsted', 'OH', 'US'),
    (rh_mpex,             'Columbus',      'OH', 'US'),
    (rh_cencam,           'Columbus',      'OH', 'US'),
    (rh_kinopicz,         'Columbus',      'OH', 'US'),
    (rh_ohd,              'Columbus',      'OH', 'US'),
    (rh_allprohd,         'Ontario',       'OH', 'US'),
    (rh_procam,           'Cincinnati',    'OH', 'US'),
    (rh_akron,            'Akron',         'OH', 'US'),
    (rh_campus,           'Kent',          'OH', 'US')

  ON CONFLICT DO NOTHING;

END $$;
