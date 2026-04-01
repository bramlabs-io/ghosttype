import AppKit
import ApplicationServices

class PermissionManager {
    private let bundleIdentifier = "com.ghosttype.app"
    private let executableHashKey = "GhostTypeExecutableHash"

    /// Check if accessibility permission is granted
    var isAccessibilityGranted: Bool {
        return AXIsProcessTrusted()
    }

    /// Called on app launch to handle permission state
    func checkAndHandlePermissions() {
        let currentHash = getExecutableHash()
        let storedHash = UserDefaults.standard.string(forKey: executableHashKey)

        // Detect if the binary changed (update occurred)
        let binaryChanged = storedHash != nil && storedHash != currentHash

        if binaryChanged && !isAccessibilityGranted {
            // Binary changed and we don't have permission - stale entry exists
            print("GhostType: Binary changed, resetting stale accessibility permission...")
            resetAccessibilityPermission()
        }

        // Store current hash for future comparison
        UserDefaults.standard.set(currentHash, forKey: executableHashKey)

        // Check if we need to request permission
        if !isAccessibilityGranted {
            requestAccessibilityPermission()
        }
    }

    /// Get a hash of the current executable to detect updates
    private func getExecutableHash() -> String? {
        guard let executablePath = Bundle.main.executablePath else {
            return nil
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: executablePath)
            // Use modification date + size as a simple "hash" to detect changes
            let modDate = attributes[.modificationDate] as? Date ?? Date()
            let size = attributes[.size] as? Int ?? 0
            return "\(modDate.timeIntervalSince1970)-\(size)"
        } catch {
            return nil
        }
    }

    /// Reset accessibility permission for this app using tccutil
    private func resetAccessibilityPermission() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", bundleIdentifier]

        do {
            try process.run()
            process.waitUntilExit()
            print("GhostType: Cleared stale accessibility permission entry")
        } catch {
            print("GhostType: Failed to reset accessibility permission: \(error)")
        }
    }

    /// Request accessibility permission with system prompt
    private func requestAccessibilityPermission() {
        // This will trigger the system prompt if not already trusted
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // Show alert explaining what to do
        showPermissionAlert()
    }

    /// Show an alert explaining why permission is needed
    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = """
            GhostType needs Accessibility permission to simulate keyboard input.

            Please grant access in:
            System Settings > Privacy & Security > Accessibility

            If GhostType appears multiple times in the list, remove the old entries first (they won't have a checkmark that works).
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self.openAccessibilitySettings()
            }
        }
    }

    /// Open System Settings to Accessibility pane
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Manually reset and re-request permissions (called from menu)
    func resetAndRequestPermissions() {
        let alert = NSAlert()
        alert.messageText = "Reset Accessibility Permission?"
        alert.informativeText = """
        This will remove the current accessibility permission entry for GhostType.

        After resetting, you'll need to grant permission again in System Settings.

        Use this if permissions aren't working after an update.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset & Open Settings")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            resetAccessibilityPermission()
            // Clear stored hash so next launch behaves as fresh install
            UserDefaults.standard.removeObject(forKey: executableHashKey)
            requestAccessibilityPermission()
        }
    }
}
