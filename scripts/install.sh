#!/bin/bash
set -e
cd "$(dirname "$0")/.."

./scripts/build.sh

APP="NotchNook.app"
DEST="/Applications/$APP"

echo "Installing to $DEST..."
rm -rf "$DEST"
cp -R "$APP" "$DEST"
xattr -cr "$DEST" 2>/dev/null || true

echo "Installed. Launching..."
open "$DEST"
