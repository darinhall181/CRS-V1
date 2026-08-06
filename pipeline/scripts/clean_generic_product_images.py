"""
clean_generic_product_images.py
================================
Removes two kinds of noise from product_image that manufacturer-site scrapers
tend to sweep up along with real product photos:

  1. "Generic" images — a basename (URL path minus query string) that appears
     across an unusually large number of DISTINCT products. A real product
     photo shouldn't belong to more than a handful of closely-related SKUs;
     if a filename shows up on --threshold or more different products, it's
     almost certainly site-wide UI chrome (icons, placeholders) or a shared
     cross-sell accessory image, not a photo of any one of them.
  2. Duplicate CDN resize variants — the same image fetched at multiple
     requested widths (?wid=800, ?wid=310, no param, ...). Keeps one row per
     (product, canonical path) group.

Run this after any bulk scrape, before running upload_images_to_r2.py, so
noise never reaches R2 in the first place. Safe to re-run — idempotent.

Usage:
    python3 scripts/clean_generic_product_images.py --brand canon [--dry-run]
    python3 scripts/clean_generic_product_images.py --brand canon --threshold 5

Requires pipeline venv to be active (psycopg2).
"""

import argparse
import logging
import os
import sys
from pathlib import Path

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

repo_root = Path(__file__).resolve().parents[2]
for p in [repo_root / "pipeline" / ".env", repo_root / ".env"]:
    if p.exists():
        load_dotenv(dotenv_path=str(p), override=False)
        break

DB_URL = os.environ.get("DATABASE_URL", "")
if not DB_URL:
    sys.exit("DATABASE_URL not set")

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

ANALYZE_SQL = """
with basename_freq as (
    select regexp_replace(split_part(pi.url,'?',1), '.*/', '') as basename,
           count(distinct pi.product_id) as n
    from product_image pi
    join product p on p.id = pi.product_id
    join brand b on b.id = p.brand_id
    where b.slug = %(brand)s
    group by basename
),
noisy_basenames as (
    select basename from basename_freq where n >= %(threshold)s
),
brand_images as (
    select pi.id, pi.product_id, pi.url,
           regexp_replace(split_part(pi.url,'?',1), '.*/', '') as basename
    from product_image pi
    join product p on p.id = pi.product_id
    join brand b on b.id = p.brand_id
    where b.slug = %(brand)s
),
noise_flagged as (
    select id, product_id, url,
           (basename in (select basename from noisy_basenames)) as is_noise
    from brand_images
),
ranked as (
    select id, is_noise,
           row_number() over (partition by product_id, split_part(url,'?',1) order by id) as rn
    from noise_flagged
)
select id, is_noise, rn from ranked where is_noise or rn > 1;
"""

REPAIR_PRIMARY_SQL = """
with candidates as (
    select pi.id, pi.product_id,
           row_number() over (partition by pi.product_id order by pi.sort_order) as rn
    from product_image pi
    join product p on p.id = pi.product_id
    join brand b on b.id = p.brand_id
    where b.slug = %(brand)s
      and split_part(pi.url, '?', 1) = split_part(p.primary_image_url, '?', 1)
      and not exists (select 1 from product_image x where x.product_id = pi.product_id and x.kind = 'primary')
)
update product_image
set kind = 'primary'
where id in (select id from candidates where rn = 1);
"""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--brand", required=True, help="Brand slug, e.g. canon")
    parser.add_argument("--threshold", type=int, default=5,
                         help="Basenames on >= this many distinct products are treated as generic noise (default 5)")
    parser.add_argument("--dry-run", action="store_true", help="Report counts but don't delete")
    args = parser.parse_args()

    conn = psycopg2.connect(DB_URL)
    params = {"brand": args.brand, "threshold": args.threshold}

    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute(ANALYZE_SQL, params)
        rows = cur.fetchall()

    noise = [r for r in rows if r["is_noise"]]
    dupes = [r for r in rows if not r["is_noise"] and r["rn"] > 1]
    log.info("brand=%s threshold=%d -> generic-noise rows=%d duplicate-resize rows=%d (of %d total flagged for removal)",
              args.brand, args.threshold, len(noise), len(dupes), len(rows))

    if args.dry_run:
        log.info("[DRY RUN] no changes made")
        conn.close()
        return 0

    if not rows:
        log.info("Nothing to clean.")
        conn.close()
        return 0

    ids = [r["id"] for r in rows]
    with conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM product_image WHERE id = ANY(%s)", (ids,))
            log.info("Deleted %d rows", cur.rowcount)
            cur.execute(REPAIR_PRIMARY_SQL, params)
            log.info("Repaired kind='primary' on %d products where the hero row was a dedup casualty", cur.rowcount)

    conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
