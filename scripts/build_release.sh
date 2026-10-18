#!/usr/bin/env bash
# Builds a flavor's iOS archive and Android APK in release mode, moves them
# to release/, then deletes build/ to save space, but only once every step
# before has worked.
#
#   scripts/build_release.sh [development|production]   # development by default
#
# FLUTTER picks the Flutter command; by default it is what the owner's
# flutterN alias points to, else `flutter`. Only the archive is kept from the
# iOS build, never an IPA.
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
# flutter build ipa also tries to export an IPA, which signing may refuse;
# only the archive counts.
if ! "$flutter" build ipa --release --flavor "$flavor" -t "$entry"; then
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
if [ ! -d "$release/$name.xcarchive" ] || [ ! -f "$release/$name.apk" ]; then
  echo "Moving them failed; build/ is kept." >&2
  exit 1
fi

echo "==> 4/4 Deleting build/"
rm -rf build

echo "Done: $release"
du -sh "$release"/*
