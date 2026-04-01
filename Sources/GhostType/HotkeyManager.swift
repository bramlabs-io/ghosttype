import Carbon
import AppKit

class HotkeyManager {
    var onOCRHotkey: (() -> Void)?
    var onGhostTypeHotkey: (() -> Void)?

    private var ocrHotkeyRef: EventHotKeyRef?
    private var ghostTypeHotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // Hotkey IDs
    private let ocrHotkeyID = EventHotKeyID(signature: OSType(0x4754_4F43), id: 1)      // "GTOC"
    private let ghostTypeHotkeyID = EventHotKeyID(signature: OSType(0x4754_4F43), id: 2) // "GTOC"

    // Store reference to self for C callback
    private static var instance: HotkeyManager?

    func register() {
        HotkeyManager.instance = self

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            var hotkeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotkeyID
            )

            DispatchQueue.main.async {
                if hotkeyID.id == 1 {
                    HotkeyManager.instance?.onOCRHotkey?()
                } else if hotkeyID.id == 2 {
                    HotkeyManager.instance?.onGhostTypeHotkey?()
                }
            }

            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            nil,
            &eventHandler
        )

        // Register Shift+Cmd+C (keycode 8 = 'C')
        RegisterEventHotKey(
            UInt32(kVK_ANSI_C),
            UInt32(shiftKey | cmdKey),
            ocrHotkeyID,
            GetApplicationEventTarget(),
            0,
            &ocrHotkeyRef
        )

        // Register Shift+Cmd+V (keycode 9 = 'V')
        RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(shiftKey | cmdKey),
            ghostTypeHotkeyID,
            GetApplicationEventTarget(),
            0,
            &ghostTypeHotkeyRef
        )

        print("Hotkeys registered: Shift+Cmd+C (OCR), Shift+Cmd+V (Ghost Type)")
    }

    func unregister() {
        if let ref = ocrHotkeyRef {
            UnregisterEventHotKey(ref)
        }
        if let ref = ghostTypeHotkeyRef {
            UnregisterEventHotKey(ref)
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
        HotkeyManager.instance = nil
    }

    deinit {
        unregister()
    }
}
