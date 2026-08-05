"""
doc_fetch.py
============
Downloads PDFs discovered by doc_discovery.py, dedupes by sha256, stores them
in local storage (repo data/ symlink → ~/Documents/CRS_Database by default),
optionally uploads to Cloudflare R2, and updates product_document rows
(status='downloaded', local_path, raw_metadata.sha256/r2_url).

Usage (from pipeline/):
    python3 scripts/doc_fetch.py --brand arri --limit 3 --dry-run     # look, don't touch
    python3 scripts/doc_fetch.py --brand arri --limit 3 --no-r2 --no-db  # local disk only
    python3 scripts/doc_fetch.py --brand arri                          # full flow

Storage layout:
    local:  <repo>/data/documents/{brand}/{sha16}_{basename}.pdf
    R2:     docs/{brand}/{sha16}_{basename}.pdf
    manifest: <repo>/data/documents/manifest.json  (url → sha256, works without DB)

Env (pipeline/.env): DATABASE_URL (Neon), CF/R2 vars (same as upload_images_to_r2.py)
"""

import argparse
import hashlib
import json
import logging
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional
from urllib.parse import urlparse, unquote

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

PIPELINE_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = PIPELINE_ROOT.parent
DISCOVERED_DIR = PIPELINE_ROOT / "data" / "doc_targets" / "discovered"
DEFAULT_LOCAL_DIR = REPO_ROOT / "data" / "documents"   # → CRS_Database/documents via symlink

USER_AGENT = "AltoscopeDocBot/1.0 (+darin@altoscope.so)"


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _safe_basename(url: str) -> str:
    name = unquote(Path(urlparse(url).path).name) or "document.pdf"
    name = re.sub(r"[^A-Za-z0-9._-]+", "-", name)[:120]
    if not name.lower().endswith(".pdf"):
        name += ".pdf"
    return name


def _download(url: str, timeout: int = 60) -> Optional[bytes]:
    import requests  # lazy import
    try:
        r = requests.get(url, timeout=timeout, headers={"User-Agent": USER_AGENT})
        r.raise_for_status()
        data = r.content
        if not data.startswith(b"%PDF"):
            logger.warning("Not a PDF (magic bytes): %s", url)
            return None
        return data
    except Exception as e:
        logger.warning("Download failed %s: %s", url, e)
        return None


# ─── Manifest (local dedupe ledger, independent of DB) ───────────────────────

def _load_manifest(local_dir: Path) -> Dict[str, Any]:
    p = local_dir / "manifest.json"
    if p.exists():
        return json.loads(p.read_text())
    return {"by_url": {}, "by_sha": {}}


def _save_manifest(local_dir: Path, manifest: Dict[str, Any]) -> None:
    (local_dir / "manifest.json").write_text(json.dumps(manifest, indent=2))


# ─── R2 ──────────────────────────────────────────────────────────────────────

def _r2_client():
    import boto3  # lazy import
    from botocore.config import Config
    return boto3.client(
        "s3",
        endpoint_url=os.environ["R2_ENDPOINT_URL"],
        aws_access_key_id=os.environ["R2_ACCESS_KEY_ID"],
        aws_secret_access_key=os.environ["R2_SECRET_ACCESS_KEY"],
        region_name="auto",
        config=Config(signature_version="s3v4"),
    )


def _upload_r2(s3, bucket: str, key: str, data: bytes) -> bool:
    try:
        s3.head_object(Bucket=bucket, Key=key)
        return True  # already there — idempotent
    except Exception:
        pass
    try:
        s3.put_object(Bucket=bucket, Key=key, Body=data,
                      ContentType="application/pdf",
                      CacheControl="public, max-age=31536000, immutable")
        return True
    except Exception as e:
        logger.error("R2 upload failed %s: %s", key, e)
        return False


# ─── DB ──────────────────────────────────────────────────────────────────────

def _db_conn():
    import psycopg2
    from dotenv import load_dotenv
    load_dotenv(dotenv_path=str(PIPELINE_ROOT / ".env"), override=False)
    db_url = os.environ.get("DATABASE_URL") or os.environ.get("SUPABASE_DB_URL")
    if not db_url:
        raise RuntimeError("DATABASE_URL not set (pipeline/.env)")
    return psycopg2.connect(db_url)


def _mark_downloaded(conn, url: str, brand: str, local_path: str,
                     meta: Dict[str, Any]) -> None:
    with conn.cursor() as cur:
        cur.execute(
            """
            UPDATE product_document
               SET status = 'downloaded',
                   downloaded_at = NOW(),
                   local_path = %s,
                   raw_metadata = COALESCE(raw_metadata, '{}'::jsonb) || %s::jsonb
             WHERE url = %s
            """,
            (local_path, json.dumps(meta), url),
        )
        if cur.rowcount == 0:  # discovered via JSON-only run — insert now
            cur.execute(
                """
                INSERT INTO product_document
                    (brand_slug, product_slug, document_kind, url, status,
                     downloaded_at, local_path, raw_metadata)
                VALUES (%s, '_unmapped', 'unclassified_pdf', %s, 'downloaded',
                        NOW(), %s, %s::jsonb)
                ON CONFLICT (product_slug, document_kind, url) DO NOTHING
                """,
                (brand, url, local_path, json.dumps(meta)),
            )
    conn.commit()


# ─── Main ────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch discovered doc PDFs → local + R2 + DB")
    parser.add_argument("--brand", required=True, help="Brand slug (matches discovered/*.json)")
    parser.add_argument("--input", default=None, help="Override inventory JSON path")
    parser.add_argument("--local-dir", default=str(DEFAULT_LOCAL_DIR))
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--delay", type=float, default=2.5)
    parser.add_argument("--dry-run", action="store_true", help="List what would happen; no writes")
    parser.add_argument("--no-r2", action="store_true")
    parser.add_argument("--no-db", action="store_true")
    args = parser.parse_args()

    inv_path = Path(args.input) if args.input else DISCOVERED_DIR / f"{args.brand}_docs.json"
    if not inv_path.exists():
        logger.error("No inventory at %s — run doc_discovery.py first", inv_path)
        return 1
    docs = json.loads(inv_path.read_text())["docs"]
    if args.limit:
        docs = docs[: args.limit]

    local_dir = Path(args.local_dir)
    brand_dir = local_dir / args.brand
    if not args.dry_run:
        brand_dir.mkdir(parents=True, exist_ok=True)
    manifest = _load_manifest(local_dir) if not args.dry_run else {"by_url": {}, "by_sha": {}}

    use_r2 = not args.no_r2 and not args.dry_run
    s3 = bucket = r2_public = None
    if use_r2:
        from dotenv import load_dotenv
        load_dotenv(dotenv_path=str(PIPELINE_ROOT / ".env"), override=False)
        required = ["R2_ENDPOINT_URL", "R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY",
                    "R2_BUCKET_NAME", "R2_PUBLIC_URL"]
        missing = [k for k in required if not os.environ.get(k)]
        if missing:
            logger.error("Missing R2 env vars: %s (use --no-r2 to skip)", ", ".join(missing))
            return 1
        s3 = _r2_client()
        bucket = os.environ["R2_BUCKET_NAME"]
        r2_public = os.environ["R2_PUBLIC_URL"].rstrip("/")

    conn = None
    if not args.no_db and not args.dry_run:
        conn = _db_conn()

    stats = {"downloaded": 0, "dup": 0, "skipped": 0, "failed": 0}
    for i, d in enumerate(docs, 1):
        url = d["url"]
        if url in manifest["by_url"]:
            stats["skipped"] += 1
            continue
        if args.dry_run:
            logger.info("[DRY RUN] would fetch %s", url)
            stats["downloaded"] += 1
            continue

        data = _download(url)
        if data is None:
            stats["failed"] += 1
            continue

        sha = hashlib.sha256(data).hexdigest()
        basename = _safe_basename(url)
        fname = f"{sha[:16]}_{basename}"

        if sha in manifest["by_sha"]:
            # Same content at a new URL — record alias, don't re-store
            manifest["by_url"][url] = sha
            logger.info("[%d/%d] dup content (alias): %s", i, len(docs), basename)
            stats["dup"] += 1
        else:
            local_path = brand_dir / fname
            local_path.write_bytes(data)
            r2_key = f"docs/{args.brand}/{fname}"
            r2_url = None
            if use_r2 and _upload_r2(s3, bucket, r2_key, data):
                r2_url = f"{r2_public}/{r2_key}"
            manifest["by_sha"][sha] = {"file": str(local_path.relative_to(local_dir)),
                                       "r2_key": r2_key if use_r2 else None,
                                       "bytes": len(data), "first_url": url,
                                       "fetched_at": _utc_now_iso()}
            manifest["by_url"][url] = sha
            logger.info("[%d/%d] ✓ %s (%.1f KB)%s", i, len(docs), basename,
                        len(data) / 1024, " → R2" if r2_url else "")
            stats["downloaded"] += 1
            if conn:
                _mark_downloaded(conn, url, args.brand, str(local_path),
                                 {"sha256": sha, "bytes": len(data),
                                  "r2_key": r2_key if use_r2 else None,
                                  "r2_url": r2_url, "title": d.get("title"),
                                  "via": d.get("via")})

        _save_manifest(local_dir, manifest)
        time.sleep(args.delay)

    if conn:
        conn.close()
    logger.info("Done. downloaded=%d dup=%d skipped=%d failed=%d → %s",
                stats["downloaded"], stats["dup"], stats["skipped"], stats["failed"], brand_dir)
    return 0 if stats["failed"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
