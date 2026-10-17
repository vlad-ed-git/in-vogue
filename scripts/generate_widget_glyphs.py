#!/usr/bin/env python3
"""Write the Android widget's weather glyphs from the app's spec paths.

    python3 scripts/generate_widget_glyphs.py

Reads weatherStillPaths in lib/core/presentation/components/weather/
weather_glyph_paths.dart (copied from design-spec) and writes one vector
drawable per glyph, in Rose, to android/app/src/main/res/drawable/
widget_glyph_<name>.xml. test/core/android_widget_configuration_test.dart
checks each drawable still holds its path.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "lib/core/presentation/components/weather/weather_glyph_paths.dart"
OUT = ROOT / "android/app/src/main/res/drawable"

block = SOURCE.read_text(encoding="utf-8").split("const weatherStillPaths = <String, String>{", 1)[1]
paths = dict(re.findall(r"'([a-z-]+)':\s*'([^']+)'", block.split("};", 1)[0]))
for name, data in sorted(paths.items()):
    (OUT / f"widget_glyph_{name.replace('-', '_')}.xml").write_text(
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
print(f"{len(paths)} glyphs -> {OUT.relative_to(ROOT)}")
