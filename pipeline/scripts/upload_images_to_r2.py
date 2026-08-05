"""
upload_images_to_r2.py
======================
Downloads product images from their current URLs (stored in Supabase) and
uploads them to Cloudflare R2, then updates the Supabase rows to point at
the new R2 URLs.

Usage:
    python3 backend/scripts/upload_images_to_r2.py [--dry-run] [--brand canon]

Required environment variables (set in backend/.env):
    DATABASE_URL          Postgres connection string (Neon)
    CF_ACCOUNT_ID         Cloudflare account ID
    R2_ACCESS_KEY_ID      R2 API token access key
    R2_SECRET_ACCESS_KEY  R2 API token secret key
    R2_BUCKET_NAME        Name of the R2 bucket
    R2_ENDPOINT_URL       https://<account_id>.r2.cloudflarestorage.com
    R2_PUBLIC_URL         Public base URL for the bucket (e.g. https://pub-xxx.r2.dev)
"""

import argparse
import logging
import mimetypes
import os
import sys
import time
from pathlib import Path
from typing import Optional
from urllib.parse import urlparse

import boto3
import psycopg2
import psycopg2.extras
import requests
from botocore.config import Config
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

# ─── Env loading ──────────────────────────────────────────────────────────────

def _load_env() -> None:
    repo_root = Path(__file__).resolve().parents[2]
    for p in [repo_root / "backend" / ".env", repo_root / ".env"]:
        if p.exists():
            load_dotenv(dotenv_path=str(p), override=False)
            logger.info("Loaded env: %s", p)

# ─── R2 client ────────────────────────────────────────────────────────────────

def _r2_client():
    return boto3.client(
        "s3",
        endpoint_url=os.environ["R2_ENDPOINT_URL"],
        aws_access_key_id=os.environ["R2_ACCESS_KEY_ID"],
        aws_secret_access_key=os.environ["R2_SECRET_ACCESS_KEY"],
        region_name="auto",
        config=Config(signature_version="s3v4"),
    )

# ─── Helpers ──────────────────────────────────────────────────────────────────

def _r2_key(brand_slug: str, category_slug: str, product_slug: str, original_url: str, image_id: str) -> str:
    """Build an organized R2 key from product metadata + original filename.

    The image_id (first 8 chars of the DB UUID) is prepended to the basename to
    prevent collisions when multiple images for the same product share a filename
    (e.g. 'image-unavailable.png', 'firmware@2x.jpg').
    """
    parsed = urlparse(original_url)
    basename = Path(parsed.path).name or "image"
    basename = basename.split("?")[0]
    if "." not in basename:
        basename += ".jpg"
    short_id = image_id.replace("-", "")[:8]
    return f"{brand_slug}/{category_slug}/{product_slug}/{short_id}_{basename}"


def _content_type(url: str, data: bytes) -> str:
    parsed = urlparse(url)
    ext = Path(parsed.path).suffix.lower()
    mime = mimetypes.types_map.get(ext)
    if mime:
        return mime
    # Sniff from magic bytes
    if data[:4] == b"\x89PNG":
        return "image/png"
    if data[:3] == b"\xff\xd8\xff":
        return "image/jpeg"
    if data[:4] == b"RIFF" or data[8:12] == b"WEBP":
        return "image/webp"
    return "image/jpeg"


def _download(url: str, timeout: int = 15) -> Optional[bytes]:
    try:
        resp = requests.get(url, timeout=timeout, headers={"User-Agent": "Altoscope/1.0"})
        resp.raise_for_status()
        return resp.content
    except Exception as e:
        logger.warning("Failed to download %s: %s", url, e)
        return None


def _already_r2(url: str, r2_public_url: str) -> bool:
    return url.startswith(r2_public_url)


# ─── Main ─────────────────────────────────────────────────────────────────────

def main() -> int:
    _load_env()

    parser = argparse.ArgumentParser(description="Upload product images to Cloudflare R2")
    parser.add_argument("--brand", default=None, help="Filter by brand slug (e.g. canon)")
    parser.add_argument("--dry-run", action="store_true", help="Download but do not upload or update DB")
    parser.add_argument("--skip-db-update", action="store_true", help="Upload to R2 but don't update Supabase URLs")
    parser.add_argument("--limit", type=int, default=None, help="Max images to process (for testing)")
    args = parser.parse_args()

    # Validate required env vars
    required = ["DATABASE_URL", "R2_ENDPOINT_URL", "R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY",
                "R2_BUCKET_NAME", "R2_PUBLIC_URL"]
    missing = [k for k in required if not os.environ.get(k)]
    if missing:
        logger.error("Missing required env vars: %s", ", ".join(missing))
        return 1

    bucket = os.environ["R2_BUCKET_NAME"]
    r2_public_url = os.environ["R2_PUBLIC_URL"].rstrip("/")

    s3 = _r2_client()
    conn = psycopg2.connect(os.environ["DATABASE_URL"])

    # ── Query: all product images + product metadata ──────────────────────────
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        brand_filter = "AND b.slug = %s" if args.brand else ""
        params = (args.brand,) if args.brand else ()

        cur.execute(f"""
            SELECT
                pi.id          AS image_id,
                pi.url         AS image_url,
                pi.kind,
                pi.sort_order,
                p.id           AS product_id,
                p.slug         AS product_slug,
                p.primary_image_url,
                b.slug         AS brand_slug,
                pc.slug        AS category_slug
            FROM product_image pi
            JOIN product p ON p.id = pi.product_id
            JOIN brand b ON b.id = p.brand_id
            JOIN product_category pc ON pc.id = p.category_id
            WHERE pi.url IS NOT NULL
              AND pi.url != ''
              {brand_filter}
            ORDER BY b.slug, pc.slug, p.slug, pi.sort_order
        """, params)
        rows = cur.fetchall()

    if args.limit:
        rows = rows[:args.limit]

    logger.info("Found %d product images to process", len(rows))

    stats = {"skipped": 0, "uploaded": 0, "failed": 0, "updated_db": 0}
    # Collect DB updates to batch commit
    image_updates: list[tuple[str, str]] = []   # (new_url, image_id)
    primary_updates: dict[str, str] = {}        # product_id -> new primary_image_url

    for i, row in enumerate(rows, 1):
        original_url: str = row["image_url"]
        product_slug: str = row["product_slug"]
        brand_slug: str = row["brand_slug"]
        category_slug: str = row["category_slug"]

        # Skip if already on R2
        if _already_r2(original_url, r2_public_url):
            stats["skipped"] += 1
            continue

        key = _r2_key(brand_slug, category_slug, product_slug, original_url, row["image_id"])
        r2_url = f"{r2_public_url}/{key}"

        # Check if key already exists in R2 (idempotent)
        if not args.dry_run:
            try:
                s3.head_object(Bucket=bucket, Key=key)
                logger.debug("Already in R2, skipping upload: %s", key)
                # Only queue a DB update if the stored URL still differs
                if original_url != r2_url:
                    image_updates.append((r2_url, row["image_id"]))
                    if row["primary_image_url"] == original_url:
                        primary_updates[row["product_id"]] = r2_url
                stats["skipped"] += 1
                continue
            except Exception:
                pass  # Key doesn't exist — fall through to upload

        # Download
        data = _download(original_url)
        if data is None:
            stats["failed"] += 1
            continue

        content_type = _content_type(original_url, data)

        if args.dry_run:
            logger.info("[DRY RUN] Would upload %s → r2://%s/%s (%d bytes)", original_url, bucket, key, len(data))
            stats["uploaded"] += 1
            continue

        # Upload to R2
        try:
            s3.put_object(
                Bucket=bucket,
                Key=key,
                Body=data,
                ContentType=content_type,
                CacheControl="public, max-age=31536000, immutable",
            )
            logger.info("[%d/%d] ✓ %s → %s", i, len(rows), product_slug, r2_url)
            stats["uploaded"] += 1
        except Exception as e:
            logger.error("R2 upload failed for %s: %s", key, e)
            stats["failed"] += 1
            continue

        # Queue DB update
        image_updates.append((r2_url, row["image_id"]))
        if row["primary_image_url"] == original_url:
            primary_updates[row["product_id"]] = r2_url

        # Polite rate limit — avoid hammering the source CDN
        time.sleep(0.05)

    # ── Batch update Supabase ──────────────────────────────────────────────────
    if image_updates and not args.dry_run and not args.skip_db_update:
        with conn:
            with conn.cursor() as cur:
                # Only update rows whose URL hasn't already been set to the R2 value.
                # This makes the script fully idempotent — re-running after a partial
                # update won't hit the (product_id, url) unique constraint.
                psycopg2.extras.execute_batch(
                    cur,
                    "UPDATE product_image SET url = %s WHERE id = %s AND url IS DISTINCT FROM %s",
                    [(r2_url, img_id, r2_url) for r2_url, img_id in image_updates],
                    page_size=200,
                )
                stats["updated_db"] += len(image_updates)
                logger.info("Updated %d product_image rows", len(image_updates))

                if primary_updates:
                    psycopg2.extras.execute_batch(
                        cur,
                        "UPDATE product SET primary_image_url = %s WHERE id = %s AND primary_image_url IS DISTINCT FROM %s",
                        [(r2_url, prod_id, r2_url) for prod_id, r2_url in primary_updates.items()],
                        page_size=200,
                    )
                    logger.info("Updated %d product.primary_image_url rows", len(primary_updates))

    conn.close()

    logger.info(
        "Done. uploaded=%d skipped=%d failed=%d db_rows_updated=%d",
        stats["uploaded"], stats["skipped"], stats["failed"], stats["updated_db"],
    )
    return 0 if stats["failed"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
