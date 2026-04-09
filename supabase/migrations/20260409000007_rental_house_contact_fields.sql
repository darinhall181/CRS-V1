-- Add contact_email and phone to rental_house (company-level contact info).
-- Also add location-level overrides on rental_house_location for chains
-- where individual offices have different contact details.
--
-- Backfills emails from the Ohio rental house seed (20260409000006).

ALTER TABLE rental_house
  ADD COLUMN IF NOT EXISTS contact_email text,
  ADD COLUMN IF NOT EXISTS phone         text;

ALTER TABLE rental_house_location
  ADD COLUMN IF NOT EXISTS contact_email text,
  ADD COLUMN IF NOT EXISTS phone         text;

-- ── Backfill Ohio rental house emails ────────────────────────────────────────

UPDATE rental_house SET contact_email = 'william@ohiocinemotion.com'      WHERE slug = 'ohio-cinemotion';
UPDATE rental_house SET contact_email = 'support@clevelandcamerarental.com' WHERE slug = 'cleveland-camera-rental';
UPDATE rental_house SET contact_email = 'estore@doddcamera.com'            WHERE slug = 'dodd-camera';
UPDATE rental_house SET contact_email = 'rent@liminalspaceproductions.com' WHERE slug = 'liminal-space-rentals';
UPDATE rental_house SET contact_email = 'csmith@osvstudios.com'            WHERE slug = 'osv-studios';
UPDATE rental_house SET contact_email = 'rentals@mpex.com'                 WHERE slug = 'midwest-photo-rentals';
UPDATE rental_house SET contact_email = 'hello@kinopicz.com'               WHERE slug = 'kinopicz-american';
UPDATE rental_house SET contact_email = 'info@ohdstudios.com'              WHERE slug = 'ohd-studios';
UPDATE rental_house SET contact_email = 'cincinnati@procam.com'            WHERE slug = 'procam-cincinnati';
UPDATE rental_house SET contact_email = 'CampusCameraLab@hotmail.com'      WHERE slug = 'campus-camera';
