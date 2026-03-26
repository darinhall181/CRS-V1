import re
import logging
from typing import List, Dict, Optional, Tuple, Any

logger = logging.getLogger(__name__)

class SpecMapperService:
    def __init__(self, db_connection, category_slug: Optional[str] = None):
        self.conn = db_connection
        self.category_slug = category_slug
        self.mappings = []
        self.definitions = {}
        self._load_rules()

    def _load_rules(self):
        """Loads mappings and definitions from the database.

        When category_slug is provided only rules whose spec_definition belongs
        to that category are loaded.  This prevents cross-category rules (e.g.
        a camera lens_mount rule) from hijacking specs scraped for a different
        category (e.g. lenses).
        """
        try:
            with self.conn.cursor() as cur:
                # Load Definitions (filtered by category when provided)
                if self.category_slug:
                    cur.execute(
                        """
                        SELECT sd.id, sd.normalized_key, sd.display_name, sd.data_type, sd.unit
                        FROM spec_definition sd
                        JOIN product_category pc ON pc.id = sd.category_id
                        WHERE pc.slug = %s
                        """,
                        (self.category_slug,),
                    )
                else:
                    cur.execute("SELECT id, normalized_key, display_name, data_type, unit FROM spec_definition")

                for row in cur.fetchall():
                    self.definitions[row[0]] = {
                        "normalized_key": row[1],
                        "name": row[2],
                        "type": row[3],
                        "unit": row[4],
                    }

                # Load Mappings (filtered to the same set of definitions)
                if self.category_slug:
                    cur.execute(
                        """
                        SELECT sm.spec_definition_id, sm.extraction_pattern, sm.context_pattern, sm.priority
                        FROM spec_mapping sm
                        JOIN spec_definition sd ON sd.id = sm.spec_definition_id
                        JOIN product_category pc ON pc.id = sd.category_id
                        WHERE pc.slug = %s
                        ORDER BY sm.priority DESC
                        """,
                        (self.category_slug,),
                    )
                else:
                    cur.execute("""
                        SELECT spec_definition_id, extraction_pattern, context_pattern, priority 
                        FROM spec_mapping 
                        ORDER BY priority DESC
                    """)

                def _normalize_pattern(p: str) -> str:
                    """
                    Our SQL seeds often contain double-backslashes (e.g. '\\\\s') because they're written
                    with Postgres in mind. Python's `re` expects single-backslashes (e.g. '\\s').
                    Normalize here so one ruleset can serve both.
                    """
                    return (p or "").replace("\\\\", "\\")

                # Store as list of dicts for iteration
                self.mappings = [
                    {
                        "def_id": row[0],
                        "pattern": re.compile(_normalize_pattern(row[1]), re.IGNORECASE),
                        "context": re.compile(_normalize_pattern(row[2]), re.IGNORECASE) if row[2] else None,
                        "priority": row[3]
                    }
                    for row in cur.fetchall()
                ]
                logger.info(f"Loaded {len(self.mappings)} spec mapping rules.")
        except Exception as e:
            logger.error(f"Failed to load spec rules: {e}")

    def map_spec(self, raw_key: str, raw_context: str = "", raw_value: str = "") -> Optional[Dict[str, Any]]:
        """
        Matches a raw spec key/context to a canonical definition.
        Returns a dict with definition_id and parsed values.
        """
        best_match = None

        for rule in self.mappings:
            # Check context first if it exists
            if rule["context"]:
                if not raw_context or not rule["context"].search(raw_context):
                    continue
            
            # Check key pattern
            if rule["pattern"].search(raw_key):
                best_match = rule
                break # Since we ordered by priority DESC, the first match is the best

        if not best_match:
            return None

        def_id = best_match["def_id"]
        definition = self.definitions.get(def_id)
        
        # Parse value based on type
        parsed = self._parse_value(raw_value, definition["type"])
        
        return {
            "spec_definition_id": def_id,
            "numeric_value": parsed.get("numeric"),
            "boolean_value": parsed.get("boolean"),
            "unit_used": parsed.get("unit") or definition["unit"],
            "value_text": parsed.get("text")
        }

    def _parse_value(self, value: str, data_type: str) -> Dict[str, Any]:
        """Parses the raw value string into structured data."""
        result = {"text": value, "numeric": None, "boolean": None, "unit": None}
        
        if not value:
            return result

        clean_val = value.strip()

        if data_type == 'number':
            # Extract first number found
            match = re.search(r'([\d\.]+)', clean_val)
            if match:
                try:
                    result["numeric"] = float(match.group(1))
                    # Try to find unit after number
                    # This is naive; a better regex would be passed in per rule
                except ValueError:
                    pass
        
        elif data_type == 'boolean':
            if clean_val.lower() in ['yes', 'true', 'on', 'supported']:
                result["boolean"] = True
            elif clean_val.lower() in ['no', 'false', 'off', 'n/a']:
                result["boolean"] = False

        return result
