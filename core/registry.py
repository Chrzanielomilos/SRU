from dataclasses import dataclass
from typing import Optional, Dict, List

@dataclass
class ModuleInfo:
    app: str
    label: str
    slug: str
    icon: Optional[str] = None
    order: int = 1000
    permission: Optional[str] = None
    login_required: bool = True

_registry: Dict[str, ModuleInfo] = {}

def register(module: ModuleInfo):
    _registry[module.slug] = module

def all_modules() -> List[ModuleInfo]:
    return sorted(_registry.values(), key=lambda m: m.order)
