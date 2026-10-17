#!/usr/bin/env python3
"""Export the knowledge base's outfits as the app's outfits asset.

    python3 scripts/export_outfits.py [kb-folder] [catalog.json] [out.json]

Reads ../resources/kb/outfits.index.v1.json and outfits.v1.json and writes
assets/outfits/outfits.json with only what the app uses: each weather and
occasion cell's ranked outfit ids, and per outfit its signature, pieces (as
the catalog asset's colourway ids), try-on passes, one-line reasons and the
palette its makeup follows.
Every piece must be in the catalog asset (scripts/export_catalog.py), so
the try-on and the Shop page always show the same pieces.
Each reason is written in English, Spanish and Chinese ({"en", "es", "zh"}):
../resources/tools/kb/reasons.py builds them from the pieces, checking that
it builds the English the knowledge base holds, and kb/translations.v1.json
must name every piece.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KB = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "resources/kb"
CATALOG = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "assets/catalog/everlane_women.json"
OUT = Path(sys.argv[3]) if len(sys.argv) > 3 else ROOT / "assets/outfits/outfits.json"
sys.path.insert(0, str(KB.parent / "tools/kb"))
import reasons  # noqa: E402


def main():
    index = json.loads((KB / "outfits.index.v1.json").read_text(encoding="utf-8"))
    outfits = json.loads((KB / "outfits.v1.json").read_text(encoding="utf-8"))["outfits"]
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    retailer = catalog["retailer"]["id"]
    colourways = {colourway["id"] for piece in catalog["pieces"] for colourway in piece["colourways"]}
    products = json.loads((KB.parent / "catalog/everlane.women.json").read_text(encoding="utf-8"))["products"]
    garments = {product["handle"]: product["garment"] for product in products}
    problems = set()

    def described(piece):
        return {"title": piece["title"], "garment": garments[piece["handle"]], "role": piece["role"],
                "asLayer": piece["role"] == "layer"}

    def texts(outfit_id, outfit):
        ps = [described(piece) for piece in outfit["pieces"]]
        unnamed = reasons.missing(ps)
        problems.update(f"no translation for {name!r}" for name in unnamed)
        out = {}
        for cell, english in outfit["reasons"].items():
            if unnamed:
                continue
            if reasons.reason(ps, *cell.split("|")) != english:
                problems.add(f"{outfit_id} {cell}: builds another English reason than the knowledge base's")
            out[cell] = {"en": english, **{lang: reasons.reason_in(lang, ps, *cell.split("|"))
                                           for lang in reasons.LANGUAGES}}
        return out

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
            "reasons": texts(outfit_id, outfit),
            "palette": outfit["palette"],
        }
    if problems:
        sys.exit("\n".join(sorted(problems)))
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
