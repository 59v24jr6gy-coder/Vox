import Foundation
import AppKit
import ApplicationServices

class TextInserter {

    // MARK: - Public API

    func insert(text: String, method: InsertionMethod) {
        switch method {
        case .axAPI:
            if !insertViaAXAPI(text: text) {
                print("[TextInserter] AX API fehlgeschlagen, Fallback auf Clipboard")
                insertViaClipboard(text: text)
            }
        case .clipboard:
            insertViaClipboard(text: text)
        }
    }

    // MARK: - AX API

    @discardableResult
    private func insertViaAXAPI(text: String) -> Bool {
        guard AXIsProcessTrusted() else {
            print("[TextInserter] Keine Accessibility-Berechtigung")
            return false
        }

        let systemWide = AXUIElementCreateSystemWide()

        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard result == .success, let element = focusedElement else {
            print("[TextInserter] Kein fokussiertes Element gefunden (AXError: \(result.rawValue))")
            return false
        }

        let axElement = element as! AXUIElement  // swiftlint:disable:this force_cast

        // Prüfen ob Element editierbar ist
        var isSettable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(axElement, kAXValueAttribute as CFString, &isSettable)

        if isSettable.boolValue {
            // Direkt den selektierten Text ersetzen
            let setResult = AXUIElementSetAttributeValue(
                axElement,
                kAXSelectedTextAttribute as CFString,
                text as CFTypeRef
            )

            if setResult == .success {
                print("[TextInserter] Text via AX API eingefügt")
                return true
            }
        }

        print("[TextInserter] AX Einfügen fehlgeschlagen, Element nicht editierbar")
        return false
    }

    // MARK: - Clipboard Fallback

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
