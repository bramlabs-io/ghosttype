import AppKit
import ApplicationServices

class PermissionManager {
    private let executableHashKey = "GhostTypeExecutableHash"
    private let permissionShownKey = "GhostTypePermissionDialogShown"

    /// Check if accessibility permission is granted
    var isAccessibilityGranted: Bool {
        return AXIsProcessTrusted()
    }

    /// Called on app launch to handle permission state
    func checkAndHandlePermissions() {
        let currentHash = getExecutableHash()
        let storedHash = UserDefaults.standard.string(forKey: executableHashKey)
        let binaryChanged = storedHash != nil && storedHash != currentHash

        // Store current hash for future comparison
        UserDefaults.standard.set(currentHash, forKey: executableHashKey)

        if isAccessibilityGranted {
            // Permission granted, clear the "shown" flag for next time
            UserDefaults.standard.removeObject(forKey: permissionShownKey)
            return
        }

        // Not trusted - trigger system prompt (without our own dialog)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // Only show our guidance dialog once per install/update, not every launch
        let dialogShown = UserDefaults.standard.bool(forKey: permissionShownKey)

        if binaryChanged || !dialogShown {
            UserDefaults.standard.set(true, forKey: permissionShownKey)

            // Delay our dialog so it doesn't appear on top of system dialog
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                // Check again - user might have granted permission via system dialog
                if !AXIsProcessTrusted() {
                    self?.showPermissionAlert(binaryChanged: binaryChanged)
                }
            }
        }
    }

    /// Get a hash of the current executable to detect updates
    private func getExecutableHash() -> String? {
        guard let executablePath = Bundle.main.executablePath else {
            return nil
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: executablePath)
            let modDate = attributes[.modificationDate] as? Date ?? Date()
            let size = attributes[.size] as? Int ?? 0
            return "\(modDate.timeIntervalSince1970)-\(size)"
        } catch {
            return nil
        }
    }

    /// Show an alert explaining why permission is needed
    private func showPermissionAlert(binaryChanged: Bool) {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"

        if binaryChanged {
            alert.informativeText = """
            GhostType was updated and needs permission re-granted.

            The old entry in System Settings won't work anymore.
            You must REMOVE it and add GhostType again:

            1. Go to System Settings > Privacy & Security > Accessibility
            2. Find GhostType and REMOVE it (select, then click - or press Delete)
            3. Click + and add GhostType from Applications
            4. Enable the checkbox
            """
        } else {
            alert.informativeText = """
            GhostType needs Accessibility permission to simulate keyboard input.

            If GhostType already appears in the list but isn't working:
            REMOVE it and add it again.

            1. Go to System Settings > Privacy & Security > Accessibility
            2. Click + and add GhostType from Applications
            3. Enable the checkbox
            """
        }

        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
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
        // Clear stored hash so next launch shows the dialog
        UserDefaults.standard.removeObject(forKey: executableHashKey)
        UserDefaults.standard.removeObject(forKey: permissionShownKey)

        let alert = NSAlert()
        alert.messageText = "Permission Reset"
        alert.informativeText = """
        To fix permissions after an update:

        1. Open System Settings > Privacy & Security > Accessibility
        2. Find GhostType and REMOVE it (click - or press Delete)
        3. Click + and re-add GhostType from Applications
        4. Make sure the checkbox is enabled
        5. Restart GhostType
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "OK")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }
}
