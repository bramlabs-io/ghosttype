#!/bin/bash
set -e

# Build script for GhostType
# Creates a proper macOS .app bundle

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="GhostType"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building GhostType..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build with Swift in release mode
cd "$PROJECT_DIR"
swift build -c release

# Create app bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp ".build/release/GhostType" "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "$PROJECT_DIR/Info.plist" "$APP_BUNDLE/Contents/"

# Copy resources
cp -r "$PROJECT_DIR/Assets.xcassets" "$APP_BUNDLE/Contents/Resources/"
cp "$PROJECT_DIR/Sources/GhostType/Resources/MenuBarIcon.png" "$APP_BUNDLE/Contents/Resources/"

# Copy SPM resource bundle (required for Bundle.module to work)
cp -r ".build/release/GhostType_GhostType.bundle" "$APP_BUNDLE/Contents/Resources/"

# Create icns from the PNG icons
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

# Copy icons with correct names for iconutil
cp "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png"
cp "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/icon_32x32.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png"
cp "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/icon_64x64.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png"
cp "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png"
cp "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png"
cp "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png"

# Generate icns file
iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET_DIR"

# Update Info.plist to reference icns file
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP_BUNDLE/Contents/Info.plist"

echo ""
echo "Build complete: $APP_BUNDLE"
echo ""
echo "To test the app, run:"
echo "  open $APP_BUNDLE"
