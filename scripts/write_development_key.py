#!/usr/bin/env python3
"""Write assets/development/youcam_api_key.txt, the YouCam key development builds bundle.

    python3 scripts/write_development_key.py

Reads secrets/youcam_api.txt. Both files are git-ignored, and pubspec.yaml
bundles assets/development/ for the development flavor only, so production
builds carry no key. Run it again after the key changes, then rebuild.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

key = (ROOT / "secrets" / "youcam_api.txt").read_text(encoding="utf-8").strip()
if not key:
    raise SystemExit("secrets/youcam_api.txt is empty")
out = ROOT / "assets" / "development" / "youcam_api_key.txt"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(key + "\n", encoding="utf-8")
out.chmod(0o600)
print(f"Wrote {out.relative_to(ROOT)} (key not shown)")
