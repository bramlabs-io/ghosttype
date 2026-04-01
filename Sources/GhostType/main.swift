import AppKit

// Create and retain the app delegate
let delegate = AppDelegate()

// Setup the application
let app = NSApplication.shared
app.delegate = delegate

// Activate the app (needed for menu bar to appear)
app.activate(ignoringOtherApps: true)

// Run the main event loop
app.run()
