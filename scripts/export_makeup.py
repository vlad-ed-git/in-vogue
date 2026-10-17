#!/usr/bin/env python3
"""Export the knowledge base's makeup recipes as the app's makeup asset.

    python3 scripts/export_makeup.py [kb-folder] [out.json]

Reads ../resources/kb/makeup.index.v1.json and makeup.v1.json and writes
assets/makeup/recipes.json: each step once (title, how to apply it, products
and the YouCam Makeup VTO effects, with {skin}, {concealer}, {brow} and
{nudeLip} filled in at run time), and each recipe as its variant, the
indexes of its steps and the colours of its cheeks and lips, named as
makeup.v1.json names them. Recipes are keyed
occasion|outfit palette|shade group|contrast|weather.
A step's title, how-to and products are written in English, Spanish and
Chinese ({"en", "es", "zh"}) from kb/translations.v1.json: a how-to as its
sentence, then the weather notes after it. Every text must be there.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KB = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "resources/kb"
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "assets/makeup/recipes.json"
# Between a how-to's sentences.
SEPARATORS = {"es": " ", "zh": ""}


def colour_name(table, shade, hex_colour):
    """The name of the colour [hex_colour] has in [table] for [shade]."""
    for name, shades in table.items():
        if shades[shade].upper() == hex_colour.upper():
            return name
    return None


def first_colour(steps, category):
    for step in steps:
        for effect in step["effects"]:
            if effect["category"] == category:
                return effect["palettes"][0]["color"]
    return None


def translator(problems):
    words = json.loads((KB / "translations.v1.json").read_text(encoding="utf-8"))["makeup"]

    def translated(kind, english):
        found = words[kind].get(english)
        if found is None:
            problems.add(f"no translation for {kind} {english!r}")
            return {"en": english}
        return {"en": english, **{lang: found[lang] for lang in SEPARATORS}}

    def how_to(english):
        sentence, notes = english, []
        while note := next((n for n in words["notes"] if sentence.endswith(f" {n}")), None):
            notes.insert(0, note)
            sentence = sentence[: -len(note) - 1]
        found = words["howTos"].get(sentence)
        if found is None:
            problems.add(f"no translation for howTos {sentence!r}")
            return {"en": english}
        return {"en": english, **{lang: separator.join([found[lang]] + [words["notes"][n][lang] for n in notes])
                                  for lang, separator in SEPARATORS.items()}}

    return translated, how_to


def main():
    index = json.loads((KB / "makeup.index.v1.json").read_text(encoding="utf-8"))
    colours = json.loads((KB / "makeup.v1.json").read_text(encoding="utf-8"))["colors"]
    problems = set()
    translated, how_to = translator(problems)
    table, positions, recipes = [], {}, {}
    for key, recipe in sorted(index["recipes"].items()):
        shade = key.split("|")[2]
        blush = first_colour(recipe["steps"], "blush")
        lip = first_colour(recipe["steps"], "lip_color")
        cheeks = blush and colour_name(colours["blush"], shade, blush)
        lips = "nude" if lip == "{nudeLip}" else lip and colour_name(colours["lip"], shade, lip)
        if not cheeks or not lips:
            sys.exit(f"{key}: cheeks {blush} or lips {lip} not in makeup.v1.json")
        ids = []
        for step in recipe["steps"]:
            text = json.dumps(step, sort_keys=True)
            if text not in positions:
                positions[text] = len(table)
                table.append({
                    "title": translated("titles", step["title"]),
                    "howTo": how_to(step["howTo"]),
                    "products": [translated("products", product) for product in step["products"]],
                    "effects": step["effects"],
                })
            ids.append(positions[text])
        recipes[key] = {"variant": recipe["variant"], "cheeks": cheeks, "lips": lips, "steps": ids}
    if problems:
        sys.exit("\n".join(sorted(problems)))
    out = {
        "version": index["version"],
        "key": index["key"],
        "placeholders": index["runtimePlaceholders"],
        "steps": table,
        "recipes": recipes,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"{len(recipes)} recipes, {len(table)} steps -> {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
