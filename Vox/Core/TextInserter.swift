import Foundation
import AppKit

class TextInserter {

    // MARK: - Public API

    func insert(text: String) {
        insertViaClipboard(text: text)
    }

    // MARK: - Clipboard + Cmd+V

    private func insertViaClipboard(text: String) {
        let pasteboard = NSPasteboard.general

        // Alten Clipboard-Inhalt sichern
        let oldTypes = pasteboard.types ?? []
        var savedItems: [String: Any] = [:]
        for type in oldTypes {
            if let data = pasteboard.data(forType: type) {
                savedItems[type.rawValue] = data
            }
        }

        // Text in Clipboard kopieren
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // CMD+V simulieren
        simulatePaste()

        // Clipboard nach kurzer Verzögerung wiederherstellen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            pasteboard.clearContents()
            for (typeRaw, value) in savedItems {
                if let data = value as? Data {
                    pasteboard.setData(data, forType: NSPasteboard.PasteboardType(rawValue: typeRaw))
                }
            }
            print("[TextInserter] Clipboard wiederhergestellt")
        }

        print("[TextInserter] Text via Clipboard eingefügt")
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)

        // CMD+V keyDown
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        // CMD+V keyUp
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}
