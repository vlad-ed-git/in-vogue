#!/usr/bin/env python3
"""Copy the curated outfit catalog into the recommender's tests.

    python3 scripts/export_catalog_fixture.py      # writes test/fixtures/catalog_v2.json.gz

Reads the build in ../resources/catalog/firestore/outfits.v2.json (made by build_outfit_catalog.py) and
gives each outfit a stand-in picture link, since the real download links are made at upload. Run it
whenever the catalog is rebuilt, so the tests check the outfits the app reads.
"""
import gzip
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT.parent / "resources" / "catalog" / "firestore" / "outfits.v2.json"
OUT = ROOT / "test" / "fixtures" / "catalog_v2.json.gz"


def main():
    build = json.loads(BUILD.read_text())
    for outfit in build["outfits"]:
        outfit["image"]["url"] = f"https://example.invalid/{outfit['id']}.jpg"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(gzip.compress(json.dumps(build, separators=(",", ":")).encode(), mtime=0))
    print(f"wrote {OUT.relative_to(ROOT)}: {len(build['outfits'])} outfits, version {build['version']}"
          f" ({OUT.stat().st_size / 1e3:.0f} KB)")


if __name__ == "__main__":
    main()
