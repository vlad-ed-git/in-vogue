#!/usr/bin/env bash
# Builds a flavor's iOS archive and Android APK in release mode, moves them
# to release/, then deletes build/ to save space, but only once every step
# before has worked.
#
#   scripts/build_release.sh [development|production]   # development by default
#
# FLUTTER picks the Flutter command; by default it is what the owner's
# flutterN alias points to, else `flutter`. EXPORT_METHOD, when set, is passed
# to `flutter build ipa --export-method`. The IPA is exported when signing
# allows it; the archive is kept either way.
set -euo pipefail

cd "$(dirname "$0")/.."

flavor="${1:-development}"
case "$flavor" in
  development | production) ;;
  *)
    echo "Usage: $0 [development|production]" >&2
    exit 64
    ;;
esac

flutter="${FLUTTER:-}"
if [ -z "$flutter" ]; then
  flutter="$(zsh -ic 'alias flutterN' 2>/dev/null | sed -E "s/^flutterN=//; s/^'(.*)'$/\1/" || true)"
fi
flutter="${flutter:-$(command -v flutter || true)}"
if [ -z "$flutter" ]; then
  echo "No Flutter found: set FLUTTER to the flutter command." >&2
  exit 1
fi

version="$(sed -n 's/^version: *//p' pubspec.yaml)"
name="in-vogue-$flavor-${version//+/-}"
release="release/$name-$(date +%Y%m%d-%H%M)"
entry="lib/main_$flavor.dart"
archive="build/ios/archive/Runner.xcarchive"
apk="build/app/outputs/flutter-apk/app-$flavor-release.apk"

# Only what this run builds counts.
rm -rf build/ios/archive build/ios/ipa "$apk"

echo "==> 1/4 The iOS archive ($flavor, $version)"
ipa_flags=()
if [ -n "${EXPORT_METHOD:-}" ]; then
  ipa_flags=(--export-method "$EXPORT_METHOD")
fi
# The odd expansion keeps macOS's bash 3.2 happy with an empty array.
if ! "$flutter" build ipa --release --flavor "$flavor" -t "$entry" ${ipa_flags[@]+"${ipa_flags[@]}"}; then
  echo "flutter build ipa reported an error; checking for the archive." >&2
fi
if [ ! -d "$archive" ]; then
  echo "No archive was built; build/ is kept for a look." >&2
  exit 1
fi

echo "==> 2/4 The Android APK ($flavor, $version)"
"$flutter" build apk --release --flavor "$flavor" -t "$entry"
if [ ! -f "$apk" ]; then
  echo "No APK was built; build/ is kept for a look." >&2
  exit 1
fi

echo "==> 3/4 Moving them to $release"
mkdir -p "$release"
mv "$archive" "$release/$name.xcarchive"
mv "$apk" "$release/$name.apk"
ipa="$(find build/ios/ipa -name '*.ipa' 2>/dev/null | head -n 1 || true)"
if [ -n "$ipa" ]; then
  mv "$ipa" "$release/$name.ipa"
else
  echo "No IPA was exported; the archive can be exported from Xcode's Organizer."
fi
if [ ! -d "$release/$name.xcarchive" ] || [ ! -f "$release/$name.apk" ]; then
  echo "Moving them failed; build/ is kept." >&2
  exit 1
fi

echo "==> 4/4 Deleting build/"
rm -rf build

echo "Done: $release"
du -sh "$release"/*
