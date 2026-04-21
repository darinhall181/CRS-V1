#!/bin/bash

PG17=/opt/homebrew/opt/postgresql@17/bin
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SUPABASE_DB_URL='postgresql://postgres.lceugmkwtpkfajsrxygb:mjx1tvt!xvt_CAN1huq@aws-1-us-east-1.pooler.supabase.com:5432/postgres'
NEON_DB_URL='postgresql://neondb_owner:npg_oj37CWPewESR@ep-fragrant-fire-am08qu14.c-5.us-east-1.aws.neon.tech/neondb?sslmode=require'

DUMP_FILE="$SCRIPT_DIR/supabase_data.dump"

# ── Step 1: Dump (skip if dump already exists) ────────────────────────────────
if [ -f "$DUMP_FILE" ]; then
  echo "Skipping dump — $DUMP_FILE already exists."
else
  echo "Dumping data from Supabase..."
  $PG17/pg_dump \
    --data-only \
    --no-owner \
    --no-acl \
    --format=custom \
    --exclude-table-data 'auth.*' \
    --exclude-table-data 'storage.*' \
    --exclude-table-data 'realtime.*' \
    -d "$SUPABASE_DB_URL" \
    -f "$DUMP_FILE" || { echo "pg_dump failed"; exit 1; }
fi

# ── Step 2: Patch Neon schema ─────────────────────────────────────────────────
echo "Patching Neon schema..."
$PG17/psql -v ON_ERROR_STOP=1 "$NEON_DB_URL" -f "$SCRIPT_DIR/fix_neon_schema.sql" || { echo "Schema patch failed"; exit 1; }

# ── Step 3: Truncate all app tables ──────────────────────────────────────────
echo "Truncating Neon tables..."
$PG17/psql -v ON_ERROR_STOP=1 "$NEON_DB_URL" <<'SQL' || { echo "Truncate failed"; exit 1; }
TRUNCATE TABLE
  product_compatibility_value,
  product_relationship,
  kit_template_item,
  kit_template,
  product_spec,
  product_spec_matrix,
  product_image,
  product_document,
  product,
  rental_house_inventory,
  rental_house_location,
  rental_house,
  spec_mapping,
  spec_definition,
  spec_section,
  compatibility_axis,
  product_category,
  brand
CASCADE;
SQL

# ── Step 4: Restore ───────────────────────────────────────────────────────────
echo "Restoring data into Neon..."
$PG17/pg_restore \
  --data-only \
  --no-owner \
  --no-acl \
  --no-privileges \
  -d "$NEON_DB_URL" \
  "$DUMP_FILE" || echo "pg_restore finished with warnings (check above)"

echo "Done."
