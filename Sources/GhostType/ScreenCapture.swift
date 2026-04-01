import AppKit

class ScreenCapture {
    func captureSelection(completion: @escaping (NSImage?) -> Void) {
        // Create a temporary file for the screenshot
        let tempPath = NSTemporaryDirectory() + "ghosttype_capture_\(UUID().uuidString).png"

        // Use screencapture with interactive selection
        // -i: interactive mode (user selects area)
        // -x: no sound
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", tempPath]

        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                // Check if file exists (user might have cancelled)
                if FileManager.default.fileExists(atPath: tempPath) {
                    let image = NSImage(contentsOfFile: tempPath)

                    // Clean up temp file
                    try? FileManager.default.removeItem(atPath: tempPath)

                    completion(image)
                } else {
                    completion(nil)
                }
            }
        }

        do {
            try process.run()
        } catch {
            print("Failed to start screen capture: \(error)")
            completion(nil)
        }
    }
}
