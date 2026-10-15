#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

case "${1:-}" in
  development) project=in-vogue-dev; app_id=com.invogue.app.dev ;;
  production) project=in-vogue; app_id=com.invogue.app ;;
  *) echo 'Usage: scripts/configure_firebase.sh development|production' >&2; exit 64 ;;
esac

# Each iOS build configuration needs an explicit FlutterFire mapping.
for mode in Debug Profile Release; do
  flutterfire configure \
    --yes \
    --project="$project" \
    --platforms=android,ios \
    --out="lib/firebase_options_$1.dart" \
    --ios-bundle-id="$app_id" \
    --ios-build-config="$mode-$1" \
    --ios-out="ios/flavors/$1/GoogleService-Info.plist" \
    --android-package-name="$app_id" \
    --android-out="android/app/src/$1/google-services.json"
done

# Bundle the checked-in plist locally; builds do not require FlutterFire CLI.
ruby <<'RUBY'
require 'xcodeproj'
project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
runner = project.targets.find { |target| target.name == 'Runner' }
runner.shell_script_build_phases.select { |phase| phase.name&.start_with?('FlutterFire:') }.each(&:remove_from_project)
phase = runner.shell_script_build_phases.find { |item| item.name == 'Bundle Firebase configuration' } || runner.new_shell_script_build_phase('Bundle Firebase configuration')
phase.shell_script = '"${SRCROOT}/../scripts/bundle_firebase.sh"'
phase.always_out_of_date = '1'
project.save
RUBY
