#!/usr/bin/env bash
# Generates the iOS and Android launcher icons from the logo artwork.
#
# Usage: scripts/generate_app_icons.sh [logo-dir]
#   logo-dir defaults to ../design-spec/assets/logo and must contain
#   app-icon.png (1024², no alpha), app-icon-android-foreground.png and
#   app-icon-android-monochrome.png (432², transparent).
#
# Resizes with ImageMagick (Lanczos) when available, else macOS sips.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
logo="${1:-$root/../design-spec/assets/logo}"
icon="$logo/app-icon.png"
foreground="$logo/app-icon-android-foreground.png"
monochrome="$logo/app-icon-android-monochrome.png"

for file in "$icon" "$foreground" "$monochrome"; do
  [[ -f "$file" ]] || { echo "Missing $file" >&2; exit 1; }
done

# resize <source> <pixels> <destination> [opaque]
resize() {
  local source="$1" pixels="$2" destination="$3" opaque="${4:-}"
  local width
  width="$(sips -g pixelWidth "$source" | awk '/pixelWidth/ { print $2 }')"
  if [[ "$width" == "$pixels" ]]; then
    cp "$source" "$destination"
  elif command -v magick >/dev/null; then
    local flatten=()
    [[ -n "$opaque" ]] && flatten=(-background white -alpha remove -alpha off)
    magick "$source" -colorspace sRGB -filter Lanczos -resize "${pixels}x${pixels}" \
      "${flatten[@]}" -strip "PNG:$destination"
  else
    sips -z "$pixels" "$pixels" "$source" --out "$destination" >/dev/null
  fi
}

# iOS: every size in the asset catalog, plus the 1024 for the Dark
# appearance so the icon never changes with the phone.
ios="$root/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ios_icons=(
  "20x20 iphone 2x" "20x20 iphone 3x"
  "29x29 iphone 1x" "29x29 iphone 2x" "29x29 iphone 3x"
  "40x40 iphone 2x" "40x40 iphone 3x"
  "60x60 iphone 2x" "60x60 iphone 3x"
  "20x20 ipad 1x" "20x20 ipad 2x"
  "29x29 ipad 1x" "29x29 ipad 2x"
  "40x40 ipad 1x" "40x40 ipad 2x"
  "76x76 ipad 1x" "76x76 ipad 2x"
  "83.5x83.5 ipad 2x"
  "1024x1024 ios-marketing 1x"
)
find "$ios" -name '*.png' -delete
entries=()
for spec in "${ios_icons[@]}"; do
  read -r size idiom scale <<<"$spec"
  points="${size%x*}"
  name="Icon-App-${size}@${scale}.png"
  pixels="$(awk -v p="$points" -v s="${scale%x}" 'BEGIN { printf "%d", p * s }')"
  [[ -f "$ios/$name" ]] || resize "$icon" "$pixels" "$ios/$name" opaque
  entries+=("    { \"filename\" : \"$name\", \"idiom\" : \"$idiom\", \"scale\" : \"$scale\", \"size\" : \"$size\" }")
done
entries+=("    { \"appearances\" : [ { \"appearance\" : \"luminosity\", \"value\" : \"dark\" } ], \"filename\" : \"Icon-App-1024x1024@1x.png\", \"idiom\" : \"universal\", \"platform\" : \"ios\", \"size\" : \"1024x1024\" }")
{
  echo '{'
  echo '  "images" : ['
  for i in "${!entries[@]}"; do
    separator=','
    (( i == ${#entries[@]} - 1 )) && separator=''
    echo "${entries[$i]}$separator"
  done
  echo '  ],'
  echo '  "info" : { "author" : "xcode", "version" : 1 }'
  echo '}'
} >"$ios/Contents.json"

# Android: legacy square icons, plus adaptive foreground and monochrome
# layers (108 dp) over a white background.
res="$root/android/app/src/main/res"
densities=("mdpi 1" "hdpi 1.5" "xhdpi 2" "xxhdpi 3" "xxxhdpi 4")
for spec in "${densities[@]}"; do
  read -r density factor <<<"$spec"
  dir="$res/mipmap-$density"
  mkdir -p "$dir"
  legacy="$(awk -v f="$factor" 'BEGIN { printf "%d", 48 * f }')"
  adaptive="$(awk -v f="$factor" 'BEGIN { printf "%d", 108 * f }')"
  resize "$icon" "$legacy" "$dir/ic_launcher.png" opaque
  resize "$foreground" "$adaptive" "$dir/ic_launcher_foreground.png"
  resize "$monochrome" "$adaptive" "$dir/ic_launcher_monochrome.png"
done
mkdir -p "$res/mipmap-anydpi-v26"
cat >"$res/mipmap-anydpi-v26/ic_launcher.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
XML

echo "Generated icons from $logo"
