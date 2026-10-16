#!/usr/bin/env python3
"""Write secrets/development.json, the development build's --dart-define file.

    python3 scripts/write_development_defines.py

Reads the YouCam API key from secrets/youcam_api.txt. Both files are
git-ignored; only the development flavor reads them, through its launch
configuration or `--dart-define-from-file=secrets/development.json`.
"""
import json
from pathlib import Path

SECRETS = Path(__file__).resolve().parents[1] / "secrets"

key = (SECRETS / "youcam_api.txt").read_text(encoding="utf-8").strip()
if not key:
    raise SystemExit("secrets/youcam_api.txt is empty")
out = SECRETS / "development.json"
out.write_text(json.dumps({"YOUCAM_API_KEY": key}) + "\n", encoding="utf-8")
out.chmod(0o600)
print(f"Wrote {out.relative_to(SECRETS.parent)} (key not shown)")
