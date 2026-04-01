# GhostType Distribution Guide

## Prerequisites

- **Xcode Command Line Tools** - Install with: `xcode-select --install`

## Build & Distribute

### Step 1: Build the app

```bash
./scripts/build-app.sh
```

This creates `build/GhostType.app`

### Step 2: Test locally (optional)

```bash
open build/GhostType.app
```

Grant accessibility permissions when prompted.

### Step 3: Create DMG installer

```bash
./scripts/create-dmg.sh
```

This creates `build/GhostType-Installer.dmg`

## Installation

Users can:
1. Open the DMG
2. Drag GhostType to Applications
3. Launch and grant Accessibility permissions

## Note for Users

Since this app is not signed with an Apple Developer ID, users will need to right-click the app and select "Open" the first time they launch it, then click "Open" in the dialog to bypass Gatekeeper.
