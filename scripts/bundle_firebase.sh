#!/bin/sh
set -eu
case "$CONFIGURATION" in
  *-development) flavor=development ;;
  *-production) flavor=production ;;
  *) echo "Unsupported build configuration: $CONFIGURATION" >&2; exit 1 ;;
esac
cp "${SRCROOT}/flavors/${flavor}/GoogleService-Info.plist" \
   "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
