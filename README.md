<p align="center">
  <img src="Sources/GhostType/Resources/AppIcon.png" width="800px" alt="GhostType">
</p>

<p align="center">
  A sysadmin's dream. Copy and paste text anywhere — even where you can't.
</p>

---

## Why GhostType?

Ever tried to paste a command into a VM console, remote desktop, or legacy application that doesn't support clipboard sharing? GhostType solves this by simulating real keyboard input — character by character. It also captures text from anywhere on your screen using OCR, so you can "copy" text from images, videos, or unselectable UI elements. 

## Keyboard Shortcuts

|  | Normal | Ghost |
|--|--------|-------|
| **Copy** | `Cmd + C` — Copies selected text to clipboard | `Shift + Cmd + C` — OCR captures text from screen to clipboard |
| **Paste** | `Cmd + V` — Pastes from clipboard | `Shift + Cmd + V` — Types clipboard contents using keyboard simulation |

Press `Esc` to stop ghost typing.

## Features

- **OCR Capture** — Select any area of your screen to extract text using macOS Vision framework
- **Keyboard Simulation** — Types out text character-by-character, works in VMs, remote desktops, and restricted apps
- **Adjustable Speed** — Choose from multiple typing speeds
- **Menu Bar App** — Runs quietly in your menu bar

## Install

```bash
brew install --cask bramlabs-io/ghosttype/ghosttype
```

Then launch GhostType and grant Accessibility permissions when prompted.

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

[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/)
