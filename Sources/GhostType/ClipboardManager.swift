import AppKit

class ClipboardManager {
    private let pasteboard = NSPasteboard.general

    func getText() -> String? {
        return pasteboard.string(forType: .string)
    }

    func copyText(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func getImage() -> NSImage? {
        guard let data = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) else {
            return nil
        }
        return NSImage(data: data)
    }
}
