"""
promote_catalog_to_prod.py
===========================
Promotes CATALOG tables only (product/brand/spec/rental-house data — the
tables the scraping pipeline owns) from the dev Neon branch to the
production Neon branch. Never touches app/user tables (users, productions,
packages, comments, etc.) — those only ever exist on production and must
never be overwritten by anything this script does.

Why this exists: the pipeline writes to DATABASE_URL (dev-darin branch) for
day-to-day work, so catalog changes (new products, updated specs, R2 image
URLs) build up on dev and never reach production on their own. This script
is the one deliberate, reviewable step that moves them over — not an
automatic sync, not a full branch reset.

Usage:
    # Dry run (default) — reports what WOULD change, writes nothing:
    python3 scripts/promote_catalog_to_prod.py

    # Limit to specific tables while testing:
    python3 scripts/promote_catalog_to_prod.py --tables brand product

    # Actually write to production (requires the explicit flag):
    python3 scripts/promote_catalog_to_prod.py --yes

Required environment variables (see pipeline/.env):
    DATABASE_URL       Source — dev-darin branch.
    PROD_DATABASE_URL  Target — production/default branch.
"""

import argparse
import logging
import os
from pathlib import Path
from typing import Optional

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

# ─── Env loading ──────────────────────────────────────────────────────────────

def _load_env() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    env_path = repo_root / ".env"
    if env_path.exists():
        load_dotenv(dotenv_path=str(env_path), override=False)
        logger.info("Loaded env: %s", env_path)

# ─── Catalog table allowlist ────────────────────────────────────────────────
# Explicit and hardcoded on purpose — never derived by scanning the schema,
# so a new app/user table added later can't accidentally get swept into a
# promotion just by existing. Ordered so foreign keys are always satisfied
# (referenced tables promoted before the tables that reference them).

CATALOG_TABLES = [
    "brand",
    "product_category",
    "spec_section",
    "spec_definition",
    "spec_mapping",
    "rental_house",
    "rental_house_location",
    "product",
    "product_spec",
    "product_spec_matrix",
    "product_image",
    "product_document",
    "compatibility_axis",
    "product_compatibility_value",
    "product_relationship",
    "kit_template",
    "kit_template_item",
    "rental_house_inventory",
]

# Tables deliberately NEVER in the list above (documented so it's obvious
# this is an exclusion by design, not an oversight): users, user_profile,
# session, account, verification, companies, company_members, productions,
# production_members, packages, package_items, package_department_budget,
# package_comments, package_comment_mentions, package_events, invitations,
# package_item_quote, waitlist_signup.


def _connect(database_url: str):
    return psycopg2.connect(database_url)


def _primary_key_columns(cur, table: str) -> list[str]:
    cur.execute(
        """
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
        WHERE tc.table_schema = 'public'
          AND tc.table_name = %s
          AND tc.constraint_type = 'PRIMARY KEY'
        ORDER BY kcu.ordinal_position
        """,
        (table,),
    )
    return [row[0] for row in cur.fetchall()]


def _column_names(cur, table: str) -> list[str]:
    cur.execute(
        """
        SELECT column_name FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = %s
        ORDER BY ordinal_position
        """,
        (table,),
    )
    return [row[0] for row in cur.fetchall()]


def _promote_table(src_cur, dst_cur, table: str, dry_run: bool) -> None:
    pk_cols = _primary_key_columns(src_cur, table)
    if not pk_cols:
        logger.warning("Skipping %s — no primary key found, can't upsert safely", table)
        return

    columns = _column_names(src_cur, table)
    col_list = ", ".join(f'"{c}"' for c in columns)

    src_cur.execute(f'SELECT {col_list} FROM "{table}"')
    rows = src_cur.fetchall()

    if not rows:
        logger.info("%-32s dev has 0 rows — nothing to promote", table)
        return

    pk_set = set(pk_cols)
    pk_col_list = ", ".join(f'"{c}"' for c in pk_cols)
    dst_cur.execute(f'SELECT {pk_col_list} FROM "{table}"')
    existing_pks = {tuple(row) for row in dst_cur.fetchall()}

    pk_indices = [columns.index(c) for c in pk_cols]
    would_update = sum(1 for r in rows if tuple(r[i] for i in pk_indices) in existing_pks)
    would_insert = len(rows) - would_update

    logger.info(
        "%-32s dev=%d rows -> prod: %d insert, %d update%s",
        table, len(rows), would_insert, would_update, " (dry run)" if dry_run else "",
    )

    if dry_run:
        return

    update_cols = [c for c in columns if c not in pk_set]
    conflict_target = ", ".join(f'"{c}"' for c in pk_cols)
    update_clause = ", ".join(f'"{c}" = EXCLUDED."{c}"' for c in update_cols) if update_cols else None

    upsert_sql = f'INSERT INTO "{table}" ({col_list}) VALUES %s ON CONFLICT ({conflict_target})'
    upsert_sql += f" DO UPDATE SET {update_clause}" if update_clause else " DO NOTHING"

    psycopg2.extras.execute_values(dst_cur, upsert_sql, rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--tables", nargs="*", default=None, help="Limit to these tables (default: all catalog tables)")
    parser.add_argument("--yes", action="store_true", help="Actually write to production. Omit for a dry run.")
    args = parser.parse_args()

    _load_env()

    src_url = os.environ.get("DATABASE_URL")
    dst_url = os.environ.get("PROD_DATABASE_URL")
    if not src_url or not dst_url:
        raise SystemExit("Both DATABASE_URL (dev) and PROD_DATABASE_URL (production) must be set in pipeline/.env")

    tables = args.tables if args.tables else CATALOG_TABLES
    unknown = [t for t in tables if t not in CATALOG_TABLES]
    if unknown:
        raise SystemExit(f"Not in the catalog allowlist, refusing to touch: {unknown}")

    dry_run = not args.yes
    logger.info("Mode: %s", "DRY RUN (no writes)" if dry_run else "LIVE — writing to production")
    logger.info("Tables: %s", ", ".join(tables))

    with _connect(src_url) as src_conn, _connect(dst_url) as dst_conn:
        src_cur = src_conn.cursor()
        dst_cur = dst_conn.cursor()
        try:
            for table in tables:
                _promote_table(src_cur, dst_cur, table, dry_run)
            if not dry_run:
                dst_conn.commit()
                logger.info("Committed. Production catalog tables updated.")
            else:
                dst_conn.rollback()
                logger.info("Dry run complete — nothing written. Re-run with --yes to apply.")
        except Exception:
            dst_conn.rollback()
            logger.exception("Promotion failed — rolled back, production untouched.")
            raise


if __name__ == "__main__":
    main()
