import importlib
from types import ModuleType
from typing import Dict, Tuple


_PLUGIN_IMPORT_PATHS: Dict[Tuple[str, str], str] = {
    ("canon", "camera"): "agents.spec_pipeline.product.camera.canon.plugin",
    ("canon", "lens"): "agents.spec_pipeline.product.lens.canon.plugin",
}


def load_plugin(brand_slug: str, product_type: str) -> ModuleType:
    key = ((brand_slug or "").lower(), (product_type or "").lower())
    if key not in _PLUGIN_IMPORT_PATHS:
        known = ", ".join([f"{b}:{t}" for (b, t) in sorted(_PLUGIN_IMPORT_PATHS.keys())])
        raise ValueError(f"Unknown plugin {key[0]}:{key[1]}. Known: {known}")
    return importlib.import_module(_PLUGIN_IMPORT_PATHS[key])

