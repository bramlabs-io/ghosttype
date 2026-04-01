import AppKit
import Foundation
import CoreGraphics
import Carbon

enum TypingSpeed: String, CaseIterable {
    case fast = "Fast"
    case normal = "Normal"
    case slow = "Slow"

    var delayRange: (min: UInt32, max: UInt32) {
        switch self {
        case .fast:   return (5, 15)
        case .normal: return (20, 40)
        case .slow:   return (40, 80)
        }
    }
}

class GhostTyper {
    // Delay range in milliseconds for natural typing feel
    var typingSpeed: TypingSpeed = .fast

    private var isCancelled = false
    private var eventMonitor: Any?
    private var focusObserver: NSObjectProtocol?
    private var targetApp: NSRunningApplication?

    func type(text: String, completion: @escaping () -> Void) {
        isCancelled = false
        startEscapeMonitor()
        startFocusMonitor()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            for char in text {
                if self.isCancelled {
                    break
                }

                self.typeCharacter(char)

                // Random delay for natural feel
                let range = self.typingSpeed.delayRange
                let delay = arc4random_uniform(range.max - range.min) + range.min
                usleep(delay * 1000) // Convert to microseconds
            }

            DispatchQueue.main.async {
                self.stopMonitors()
                completion()
            }
        }
    }

    func cancel() {
        isCancelled = true
    }

    private func startEscapeMonitor() {
        DispatchQueue.main.async { [weak self] in
            self?.eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if event.keyCode == UInt16(kVK_Escape) {
                    self?.cancel()
                }
            }
        }
    }

    private func startFocusMonitor() {
        DispatchQueue.main.async { [weak self] in
            // Capture the current frontmost app
            self?.targetApp = NSWorkspace.shared.frontmostApplication

            // Watch for app switches
            self?.focusObserver = NotificationCenter.default.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self,
                      let newApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let targetApp = self.targetApp else {
                    return
                }

                // Cancel if focus moved to a different app
                if newApp.processIdentifier != targetApp.processIdentifier {
                    self.cancel()
                }
            }
        }
    }

    private func stopMonitors() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let observer = focusObserver {
            NotificationCenter.default.removeObserver(observer)
            focusObserver = nil
        }
        targetApp = nil
    }

    private func typeCharacter(_ char: Character) {
        let string = String(char)

        // Handle special characters using Unicode input
        if char == "\n" {
            // Return key
            sendKeyEvent(keyCode: CGKeyCode(kVK_Return), keyDown: true)
            sendKeyEvent(keyCode: CGKeyCode(kVK_Return), keyDown: false)
        } else if char == "\t" {
            // Tab key
            sendKeyEvent(keyCode: CGKeyCode(kVK_Tab), keyDown: true)
            sendKeyEvent(keyCode: CGKeyCode(kVK_Tab), keyDown: false)
        } else {
            // Use CGEvent with Unicode string for all other characters
            typeUnicodeString(string)
        }
    }

    private func typeUnicodeString(_ string: String) {
        let source = CGEventSource(stateID: .hidSystemState)

        // Convert string to UniChar array
        var chars = [UniChar]()
        for scalar in string.unicodeScalars {
            if scalar.value <= 0xFFFF {
                chars.append(UniChar(scalar.value))
            } else {
                // Handle surrogate pairs for characters outside BMP
                let value = scalar.value - 0x10000
                chars.append(UniChar(0xD800 + (value >> 10)))
                chars.append(UniChar(0xDC00 + (value & 0x3FF)))
            }
        }

        // Create key down event with Unicode characters
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
            keyDown.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: chars)
            keyDown.post(tap: .cghidEventTap)
        }

        // Create key up event
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
            keyUp.post(tap: .cghidEventTap)
        }
    }

    private func sendKeyEvent(keyCode: CGKeyCode, keyDown: Bool) {
        let source = CGEventSource(stateID: .hidSystemState)
        if let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) {
            event.post(tap: .cghidEventTap)
        }
    }
}
