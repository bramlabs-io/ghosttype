import AppKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotkeyManager: HotkeyManager!
    private let clipboardManager = ClipboardManager()
    private let ocrService = OCRService()
    private let ghostTyper = GhostTyper()
    private let screenCapture = ScreenCapture()

    private var defaultIcon: NSImage?
    private var settingsMenu: NSMenu?

    private func log(_ message: String) {
        let logPath = "/tmp/ghosttype_debug.log"
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)\n"
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath) {
                if let handle = FileHandle(forWritingAtPath: logPath) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                FileManager.default.createFile(atPath: logPath, contents: data)
            }
        }
        print(message)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        log("GhostType starting...")

        // Hide dock icon - we're a menu bar only app
        NSApp.setActivationPolicy(.accessory)

        loadIcons()
        log("Icons loaded: \(defaultIcon != nil ? "yes" : "no")")

        setupStatusItem()
        log("Status item created: \(statusItem != nil ? "yes" : "no")")
        log("Status item button: \(statusItem?.button != nil ? "yes" : "no")")
        log("Button image: \(statusItem?.button?.image != nil ? "yes" : "no")")

        setupHotkeys()

        log("GhostType is running. Use Shift+Cmd+C for OCR, Shift+Cmd+V for Ghost Typing.")
    }

    private func loadIcons() {
        // Try loading from SPM bundle resources first
        var icon: NSImage?

        if let resourceURL = Bundle.module.url(forResource: "MenuBarIcon", withExtension: "png") {
            log("Found icon at: \(resourceURL)")
            icon = NSImage(contentsOf: resourceURL)
            log("Loaded from bundle: \(icon != nil ? "yes, size: \(icon!.size)" : "no")")
        } else {
            log("Icon not found in bundle")
        }

        // Fallback: try loading from source directory (for debug builds without bundle)
        if icon == nil {
            let srcPath = "/Users/jimmibram/Projects/ghosttype/Sources/GhostType/Resources/MenuBarIcon.png"
            log("Trying fallback path: \(srcPath)")
            icon = NSImage(contentsOfFile: srcPath)
            log("Loaded from fallback: \(icon != nil ? "yes, size: \(icon!.size)" : "no")")
        }

        if let icon = icon {
            // Resize for menu bar (18pt height, maintain aspect ratio)
            let targetHeight: CGFloat = 18
            let aspectRatio = icon.size.width / icon.size.height
            let targetWidth = targetHeight * aspectRatio

            let resizedIcon = NSImage(size: NSSize(width: targetWidth, height: targetHeight))
            resizedIcon.lockFocus()
            icon.draw(in: NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
            resizedIcon.unlockFocus()

            // Set as template so it adapts to light/dark mode
            resizedIcon.isTemplate = true

            defaultIcon = resizedIcon
            log("Resized icon to: \(resizedIcon.size)")
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Use custom icon if available, otherwise fall back to system icon
            if let icon = defaultIcon {
                button.image = icon
            } else if let sysIcon = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "GhostType") {
                sysIcon.isTemplate = true
                button.image = sysIcon
            } else {
                button.title = "GT"
            }
        }

        let menu = NSMenu()
        let titleItem = NSMenuItem(title: "GhostType", action: nil, keyEquivalent: "")
        if let icon = defaultIcon?.copy() as? NSImage {
            icon.size = NSSize(width: 16, height: 16)
            icon.isTemplate = false  // Show the actual icon, not template
            titleItem.image = icon
        }
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Capture OCR", action: #selector(captureOCR), keyEquivalent: "C"))
        menu.items.last?.keyEquivalentModifierMask = [.shift, .command]

        menu.addItem(NSMenuItem(title: "Ghost Paste", action: #selector(ghostPaste), keyEquivalent: "V"))
        menu.items.last?.keyEquivalentModifierMask = [.shift, .command]

        menu.addItem(NSMenuItem.separator())

        // Settings submenu
        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let settingsMenu = NSMenu()

        // Typing speed options
        let speedLabel = NSMenuItem(title: "Typing Speed:", action: nil, keyEquivalent: "")
        speedLabel.isEnabled = false
        settingsMenu.addItem(speedLabel)

        for speed in TypingSpeed.allCases {
            let item = NSMenuItem(title: speed.rawValue, action: #selector(setTypingSpeed(_:)), keyEquivalent: "")
            item.representedObject = speed
            item.state = ghostTyper.typingSpeed == speed ? .on : .off
            settingsMenu.addItem(item)
        }

        settingsMenu.addItem(NSMenuItem.separator())

        // Escape hint
        let escHint = NSMenuItem(title: "Press Esc to stop typing", action: nil, keyEquivalent: "")
        escHint.isEnabled = false
        settingsMenu.addItem(escHint)

        settingsItem.submenu = settingsMenu
        self.settingsMenu = settingsMenu
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit GhostType", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func setupHotkeys() {
        hotkeyManager = HotkeyManager()
        hotkeyManager.onOCRHotkey = { [weak self] in
            self?.captureOCR()
        }
        hotkeyManager.onGhostTypeHotkey = { [weak self] in
            self?.ghostPaste()
        }
        hotkeyManager.register()
    }

    @objc private func captureOCR() {
        setStatusIcon(.capturing)

        screenCapture.captureSelection { [weak self] image in
            guard let self = self, let image = image else {
                self?.setStatusIcon(.normal)
                return
            }

            self.ocrService.recognizeText(in: image) { text in
                DispatchQueue.main.async {
                    if let text = text, !text.isEmpty {
                        self.clipboardManager.copyText(text)
                        self.showNotification(title: "OCR Complete", body: "Text copied to clipboard")
                    } else {
                        self.showNotification(title: "OCR Failed", body: "No text detected")
                    }
                    self.setStatusIcon(.normal)
                }
            }
        }
    }

    @objc private func ghostPaste() {
        guard let text = clipboardManager.getText() else {
            showNotification(title: "Ghost Paste", body: "No text in clipboard")
            return
        }

        setStatusIcon(.typing)

        // Small delay to allow user to focus target window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.ghostTyper.type(text: text) {
                DispatchQueue.main.async {
                    self?.setStatusIcon(.normal)
                }
            }
        }
    }

    private func setStatusIcon(_ state: IconState) {
        guard let button = statusItem.button else { return }

        switch state {
        case .normal:
            if let icon = defaultIcon {
                button.image = icon
            }
        case .capturing:
            // Slightly different appearance during capture
            if let icon = defaultIcon?.copy() as? NSImage {
                button.image = icon
            }
        case .typing:
            // Could animate or change appearance during typing
            if let icon = defaultIcon?.copy() as? NSImage {
                button.image = icon
            }
        }
    }

    private enum IconState {
        case normal
        case capturing
        case typing
    }

    private func showNotification(title: String, body: String) {
        // Simple feedback via menu bar icon flash since UserNotifications requires entitlements
        // For a more complete solution, integrate UserNotifications framework with proper signing
        print("\(title): \(body)")
    }

    @objc private func setTypingSpeed(_ sender: NSMenuItem) {
        guard let speed = sender.representedObject as? TypingSpeed else { return }
        ghostTyper.typingSpeed = speed

        // Update checkmarks in menu
        settingsMenu?.items.forEach { item in
            if item.representedObject is TypingSpeed {
                item.state = (item.representedObject as? TypingSpeed) == speed ? .on : .off
            }
        }
    }

    @objc private func quit() {
        hotkeyManager.unregister()
        NSApp.terminate(nil)
    }
}
