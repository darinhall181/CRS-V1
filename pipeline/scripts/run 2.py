import json
import logging
import os
import sys
import argparse
from pathlib import Path


def _repo_root() -> Path:
    # backend/scripts/run.py -> backend/scripts -> backend -> repo root
    return Path(__file__).resolve().parents[2]


def _load_env_files(repo_root: Path) -> None:
    """
    Load environment variables from common .env locations (best-effort).

    This lets the pipeline run without requiring manual `export SUPABASE_DB_URL=...`
    in every shell session.
    """
    try:
        # Optional dependency (present in backend requirements)
        from dotenv import load_dotenv  # type: ignore
    except Exception:
        return

    # Precedence: backend/ .env should win over repo-root .env (common when backend
    # has its own service-specific secrets).
    candidates = [
        repo_root / "backend" / ".env.local",
        repo_root / "backend" / ".env",
        repo_root / ".env.local",
        repo_root / ".env",
    ]
    for p in candidates:
        if p.exists():
            load_dotenv(dotenv_path=str(p), override=False)
            logging.info("Loaded env file: %s", p)


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

    repo_root = _repo_root()
    _load_env_files(repo_root)

    # Ensure backend/src is importable (agents.*)
    backend_src = repo_root / "backend" / "src"
    sys.path.insert(0, str(backend_src))

    from agents.spec_pipeline.core.discovery import discover  # noqa: WPS433
    from agents.spec_pipeline.core.registry import load_plugin  # noqa: WPS433

    parser = argparse.ArgumentParser()
    parser.add_argument("--brand", default="canon")
    parser.add_argument("--product-type", default="camera")
    parser.add_argument(
        "--stage",
        default="discovery",
        choices=["discovery", "extraction", "normalize", "persist"],
    )
    parser.add_argument(
        "--normalized-path",
        default=None,
        help="Override path to normalized JSON for persist stage.",
    )
    args = parser.parse_args()

    plugin = load_plugin(args.brand, args.product_type)
    discovery_config = getattr(plugin, "DISCOVERY_CONFIG")

    if args.stage == "discovery":
        payload = discover(discovery_config)
        out_path = repo_root / discovery_config.output_path
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

        logging.info("Wrote URL inventory: %s", out_path)
        logging.info("Total URLs: %s", payload.get("total_urls"))
        return 0

    # stages requiring DB access
    db_url = os.environ.get("SUPABASE_DB_URL") or os.environ.get("DATABASE_URL")
    if args.stage in {"normalize", "persist"} and not db_url:
        raise RuntimeError("Set SUPABASE_DB_URL in backend/.env (or DATABASE_URL as fallback).")

    if args.stage == "persist":
        from agents.spec_pipeline.core.persistence import (  # noqa: WPS433
            PersistenceConfig,
            persist_normalized_json,
        )

        normalized_config = getattr(plugin, "NORMALIZATION_CONFIG")
        normalized_path = args.normalized_path or normalized_config.output_path

        normalized_path_str = str(normalized_path)
        normalized_abs = (
            normalized_path_str
            if normalized_path_str.startswith("/")
            else str(repo_root / normalized_path_str)
        )

        report = persist_normalized_json(
            PersistenceConfig(brand_slug=args.brand, product_type=args.product_type),
            normalized_json_path=normalized_abs,
            db_url=db_url,
        )
        logging.info("Persist report: %s", json.dumps(report, indent=2))
        return 0

    # stages requiring the discovery URL inventory
    url_inventory_path = repo_root / discovery_config.output_path
    if not url_inventory_path.exists():
        raise FileNotFoundError(
            f"URL inventory not found at {url_inventory_path}. Run discovery stage first."
        )

    if args.stage == "extraction":
        extract_urls = getattr(plugin, "extract_urls")
        extraction_output_path = extract_urls(str(url_inventory_path))
        logging.info("Wrote extraction JSON: %s", extraction_output_path)
        return 0

    # normalize stage
    normalize_fn = getattr(plugin, "normalize")
    normalized_output_path = normalize_fn(str(url_inventory_path), db_url=db_url)
    logging.info("Wrote normalized JSON: %s", normalized_output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

