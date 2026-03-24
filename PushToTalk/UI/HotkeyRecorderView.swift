import SwiftUI
import Carbon

struct HotkeyRecorderView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            // Hotkey-Anzeige
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isRecording
                          ? Color.accentColor.opacity(0.12)
                          : Color.secondary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecording ? Color.accentColor : Color.secondary.opacity(0.3),
                                    lineWidth: 1)
                    )
                Text(isRecording ? "Taste drücken…" : hotkeyLabel)
                    .foregroundColor(isRecording ? .accentColor : .primary)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
            }
            .frame(minWidth: 130)
            .fixedSize()

            if isRecording {
                Button("Abbrechen") { stopRecording() }
                    .controlSize(.small)
            } else {
                Button("Aufzeichnen") { startRecording() }
                    .controlSize(.small)

                if settings.customHotkeyKeyCode != 0 {
                    Button("Löschen") {
                        settings.customHotkeyKeyCode = 0
                        settings.customHotkeyModifiers = 0
                    }
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Label

    private var hotkeyLabel: String {
        guard settings.customHotkeyKeyCode != 0 else { return "Nicht gesetzt" }
        return Self.displayString(
            keyCode: settings.customHotkeyKeyCode,
            modifiers: settings.customHotkeyModifiers
        )
    }

    // MARK: - Recording

    private func startRecording() {
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard self.isRecording else { return event }

            // Escape = Abbrechen
            if event.keyCode == 53 {
                self.stopRecording()
                return nil
            }

            self.settings.customHotkeyKeyCode = Int(event.keyCode)
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            self.settings.customHotkeyModifiers = Int(mods.rawValue)
            self.stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
    }

    // MARK: - Display

    static func displayString(keyCode: Int, modifiers: Int) -> String {
        let flags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        var s = ""
        if flags.contains(.control) { s += "⌃" }
        if flags.contains(.option)  { s += "⌥" }
        if flags.contains(.shift)   { s += "⇧" }
        if flags.contains(.command) { s += "⌘" }
        s += keyName(for: keyCode)
        return s
    }

    // MARK: - Key Name

    private static func keyName(for keyCode: Int) -> String {
        let special: [Int: String] = [
            36: "↩", 48: "⇥", 49: "␣", 51: "⌫", 52: "↩", 53: "⎋",
            71: "⌧", 76: "↩",
            96: "F5",  97: "F6",  98: "F7",  99: "F3", 100: "F8",
           101: "F9", 103: "F11", 105: "F13", 107: "F14", 109: "F10",
           111: "F12", 113: "F15", 115: "↖", 116: "⇞", 117: "⌦",
           119: "↘",  121: "⇟",  122: "F1",  120: "F2", 118: "F4",
           123: "←",  124: "→",  125: "↓",  126: "↑"
        ]
        if let name = special[keyCode] { return name }
        return charForKeyCode(keyCode)?.uppercased() ?? "(\(keyCode))"
    }

    private static func charForKeyCode(_ keyCode: Int) -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let dataRef = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }

        let layout = unsafeBitCast(dataRef, to: CFData.self)
        let ptr = unsafeBitCast(CFDataGetBytePtr(layout), to: UnsafePointer<UCKeyboardLayout>.self)

        var dead: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var count = 0

        let status = UCKeyTranslate(
            ptr, UInt16(keyCode), UInt16(kUCKeyActionDisplay),
            0, UInt32(LMGetKbdType()),
            UInt32(kUCKeyTranslateNoDeadKeysMask),
            &dead, 4, &count, &chars
        )

        guard status == noErr, count > 0 else { return nil }
        let result = String(chars[0..<count].compactMap { $0 != 0 ? Character(UnicodeScalar($0)!) : nil })
        return result.isEmpty ? nil : result
    }
}
