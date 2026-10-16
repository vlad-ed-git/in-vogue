#!/usr/bin/env python3
"""Export the knowledge base's outfits as the app's outfits asset.

    python3 scripts/export_outfits.py [kb-folder] [catalog.json] [out.json]

Reads ../resources/kb/outfits.index.v1.json and outfits.v1.json and writes
assets/outfits/outfits.json with only what the app uses: each weather and
occasion cell's ranked outfit ids, and per outfit its signature, pieces (as
the catalog asset's colourway ids), try-on passes and one-line reasons.
Every piece must be in the catalog asset (scripts/export_catalog.py), so
the try-on and the Shop page always show the same pieces.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KB = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "resources/kb"
CATALOG = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "assets/catalog/everlane_women.json"
OUT = Path(sys.argv[3]) if len(sys.argv) > 3 else ROOT / "assets/outfits/outfits.json"


def main():
    index = json.loads((KB / "outfits.index.v1.json").read_text(encoding="utf-8"))
    outfits = json.loads((KB / "outfits.v1.json").read_text(encoding="utf-8"))["outfits"]
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    retailer = catalog["retailer"]["id"]
    colourways = {colourway["id"] for piece in catalog["pieces"] for colourway in piece["colourways"]}

    def colourway(handle):
        return f"{retailer}:{handle}"

    exported, dropped = {}, set()
    for outfit_id in {i for ids in index["cells"].values() for i in ids}:
        outfit = outfits[outfit_id]
        pieces = [colourway(piece["handle"]) for piece in outfit["pieces"]]
        if any(piece not in colourways for piece in pieces):
            dropped.add(outfit_id)
            continue
        exported[outfit_id] = {
            "signature": outfit["signature"],
            "pieces": pieces,
            "passes": [
                {"category": p["category"], "piece": colourway(p["handle"]), "reference": p["reference"]}
                for p in sorted(outfit["renderPlan"], key=lambda p: p["pass"])
            ],
            "reasons": outfit["reasons"],
        }
    out = {
        "version": index["version"],
        "key": index["key"],
        "cells": {cell: [i for i in ids if i in exported] for cell, ids in sorted(index["cells"].items())},
        "outfits": dict(sorted(exported.items())),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"{len(exported)} outfits in {len(out['cells'])} cells, {len(dropped)} dropped -> {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
