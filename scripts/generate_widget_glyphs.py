#!/usr/bin/env python3
"""Write the home-screen widgets' weather glyphs from the app's spec paths.

    python3 scripts/generate_widget_glyphs.py

Reads weatherStillPaths in lib/core/presentation/components/weather/
weather_glyph_paths.dart (copied from design-spec) and writes, for each glyph:
- Android: a vector drawable in Rose, android/app/src/main/res/drawable/
  widget_glyph_<name>.xml;
- iPhone: an SVG template image the widget tints Rose, ios/In Vogue Widget/
  Assets.xcassets/widget_glyph_<name>.imageset/.
test/core/android_widget_configuration_test.dart and
ios_widget_configuration_test.dart check each still holds its path.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "lib/core/presentation/components/weather/weather_glyph_paths.dart"
OUT = ROOT / "android/app/src/main/res/drawable"
IOS_OUT = ROOT / "ios/In Vogue Widget/Assets.xcassets"

block = SOURCE.read_text(encoding="utf-8").split("const weatherStillPaths = <String, String>{", 1)[1]
paths = dict(re.findall(r"'([a-z-]+)':\s*'([^']+)'", block.split("};", 1)[0]))
for name, data in sorted(paths.items()):
    asset = f"widget_glyph_{name.replace('-', '_')}"
    imageset = IOS_OUT / f"{asset}.imageset"
    imageset.mkdir(exist_ok=True)
    (imageset / f"{asset}.svg").write_text(
        f'''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 256 256">
  <!-- The spec's Phosphor Light "{name}" glyph, still. -->
  <path fill="#F7D3D8" d="{data}"/>
</svg>
''',
        encoding="utf-8",
    )
    (imageset / "Contents.json").write_text(
        f'''{{
  "images" : [
    {{
      "filename" : "{asset}.svg",
      "idiom" : "universal"
    }}
  ],
  "info" : {{
    "author" : "xcode",
    "version" : 1
  }},
  "properties" : {{
    "preserves-vector-representation" : true,
    "template-rendering-intent" : "template"
  }}
}}
''',
        encoding="utf-8",
    )
    (OUT / f"{asset}.xml").write_text(
        f'''<?xml version="1.0" encoding="utf-8"?>
<!-- The spec's Phosphor Light "{name}" glyph, still, in Rose. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="256"
    android:viewportHeight="256">
    <path
        android:fillColor="@color/widget_rose"
        android:pathData="{data}" />
</vector>
''',
        encoding="utf-8",
    )
print(f"{len(paths)} glyphs -> {OUT.relative_to(ROOT)} and {IOS_OUT.relative_to(ROOT)}")
