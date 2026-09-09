"""Application identity baked into the container; host checkouts are development builds."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def metadata():
    path = ROOT / 'release.json'
    if path.exists():
        return {k: v for k, v in json.loads(path.read_text()).items() if k != 'files'}
    return {'version': 'development', 'revision': 'development'}
