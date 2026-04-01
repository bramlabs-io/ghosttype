#!/bin/bash
set -e

# Create DMG installer for GhostType

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/GhostType.app"
DMG_NAME="GhostType-Installer"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"
VOLUME_NAME="GhostType"

echo "=== Creating GhostType DMG Installer ==="
echo ""

# Check if app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App bundle not found at $APP_BUNDLE"
    echo "Run ./scripts/build-app.sh first"
    exit 1
fi

# Remove old DMG
rm -f "$DMG_PATH"
rm -f "$BUILD_DIR/tmp.dmg"

# Create temporary DMG directory
DMG_TEMP="$BUILD_DIR/dmg-temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy app to temp directory
cp -R "$APP_BUNDLE" "$DMG_TEMP/"

# Create symlink to Applications
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG
echo "Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$DMG_TEMP"

echo ""
echo "=== Done! ==="
echo "DMG installer created: $DMG_PATH"
echo ""
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
