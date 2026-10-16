#!/usr/bin/env python3
"""Export the pulled catalog as the app's picks asset.

    python3 scripts/export_catalog.py [catalog.json] [out.json]

Reads ../resources/catalog/everlane.women.json (the Shopify Global Catalog
pull) and writes assets/catalog/everlane_women.json: one entry per style with
its colourways, worn photo, product link, material and warmth bands. Prices
are left out: the app never shows them.
"""
import json
import statistics
import sys
from collections import OrderedDict, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "resources/catalog/everlane.women.json"
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "assets/catalog/everlane_women.json"

BAND_ORDER = ["hot", "warm", "mild", "cool", "cold"]

# Colour for a family nobody measured.
NEUTRAL = "#9a9a98"


def family_colours(products):
    """The median measured colour of each colour family, to stand in for
    colourways whose flat-lay was not measured."""
    measured = defaultdict(list)
    for product in products:
        hex_colour = product.get("colorHex")
        if hex_colour:
            measured[product["colorFamily"]].append(
                [int(hex_colour[i:i + 2], 16) for i in (1, 3, 5)])
    return {
        family: "#" + "".join(f"{int(statistics.median(c[i] for c in colours)):02x}" for i in range(3))
        for family, colours in measured.items()
    }


def photo(product):
    reference = product.get("referenceImage") or {}
    return reference.get("url") or (product.get("images") or [None])[0]


def main():
    catalog = json.loads(SOURCE.read_text(encoding="utf-8"))
    stand_ins = family_colours(catalog["products"])
    styles = OrderedDict()
    for product in catalog["products"]:
        if product.get("availability") != "in_stock":
            continue
        url = photo(product)
        if not url:
            continue
        key = (product["title"], product["category"])
        style = styles.setdefault(key, {
            "id": product["handle"],
            "name": product["title"],
            "category": product["category"],
            "bands": set(),
            "colourways": [],
        })
        style["bands"].update(product.get("warmthBands") or [])
        style["colourways"].append({
            "id": product["id"],
            "name": product["colorName"],
            "hex": product.get("colorHex") or stand_ins.get(product["colorFamily"], NEUTRAL),
            "photo": url,
            "flat": product.get("flatImage"),
            "url": product["canonicalProductUrl"],
            "material": product.get("materialDescription"),
        })
    out = {
        "retailer": catalog["retailer"],
        "source": "Shopify Global Catalog",
        "pieces": [
            {**style, "bands": [b for b in BAND_ORDER if b in style["bands"]]}
            for style in styles.values()
        ],
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"{len(out['pieces'])} pieces, {sum(len(p['colourways']) for p in out['pieces'])} colourways -> {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
