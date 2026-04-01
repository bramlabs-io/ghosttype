<p align="center">
  <img src="Sources/GhostType/Resources/AppIcon.png" width="400px" alt="GhostType">
</p>

<h1 align="center">GhostType</h1>

<p align="center">
  A macOS menu bar app that captures text from your screen and types it out character-by-character.
</p>

<p align="center">
  You can <a href="https://github.com/bramlabs-io/ghosttype/releases/latest">Download</a> installer from Git Releases.
</p>

---

## Features

- **OCR Capture** — Select any area of your screen to extract text using macOS Vision framework
- **Ghost Typing** — Types out clipboard contents character-by-character instead of pasting
- **Adjustable Speed** — Choose from multiple typing speeds
- **Menu Bar App** — Runs quietly in your menu bar

## Keyboard Shortcuts

|  | Normal | Ghost |
|--|--------|-------|
| **Copy** | `Cmd + C` | `Shift + Cmd + C` — OCR capture from screen |
| **Paste** | `Cmd + V` | `Shift + Cmd + V` — Types out character-by-character |

Press `Esc` to stop ghost typing.

Use Ghost Paste when normal paste is blocked or detected.

## Install

1. Download the `.dmg` from [Releases](https://github.com/bramlabs-io/ghosttype/releases/latest)
2. Open the DMG and drag GhostType to Applications
3. Launch GhostType
4. Grant Accessibility permissions when prompted

> Since this app is unsigned, right-click and select "Open" the first time you launch it.

---

## Development

### Prerequisites

- macOS 12.0+
- Xcode Command Line Tools: `xcode-select --install`

### Dev Mode

```bash
swift build
./startdev.sh
```

Runs the debug build directly without creating an app bundle.

### Build

```bash
# Build the app bundle
./scripts/build-app.sh

# Run it
open build/GhostType.app
```

### Create Installer

```bash
./scripts/create-dmg.sh
```

Creates `build/GhostType-Installer.dmg`

### Project Structure

```
Sources/GhostType/
├── main.swift           # Entry point
├── AppDelegate.swift    # Menu bar setup and coordination
├── ScreenCapture.swift  # Screen selection overlay
├── OCRService.swift     # Vision framework text recognition
├── GhostTyper.swift     # Character-by-character typing
├── HotkeyManager.swift  # Global keyboard shortcuts
└── ClipboardManager.swift
```

## License

MIT
