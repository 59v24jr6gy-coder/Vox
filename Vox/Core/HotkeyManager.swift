import Foundation
import CoreGraphics
import Carbon

class HotkeyManager {
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isKeyDown = false
    private var settings: SettingsStore { .shared }

    var isRunning: Bool { eventTap != nil }

    // MARK: - Start / Stop

    func start() {
        guard eventTap == nil else {
            print("[HotkeyManager] Bereits aktiv, kein Neustart nötig")
            return
        }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        // passUnretained: HotkeyManager ist Singleton (AppState.shared.hotkeyManager),
        // lebt für die gesamte App-Laufzeit — kein passRetained nötig
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, userInfo -> Unmanaged<CGEvent>? in
                guard let userInfo else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: selfPtr
        ) else {
            print("[HotkeyManager] EventTap konnte nicht erstellt werden – Accessibility-Berechtigung fehlt?")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("[HotkeyManager] EventTap aktiv")
    }

    func stop() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        print("[HotkeyManager] EventTap gestoppt")
    }

    // MARK: - Event Handler

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                print("[HotkeyManager] Tap nach Timeout reaktiviert")
            }
            return Unmanaged.passRetained(event)
        }

        if settings.useGlobeKey {
            return handleGlobeKey(type: type, event: event)
        } else {
            return handleCustomKey(type: type, event: event)
        }
    }

    // MARK: - Globe Key (flagsChanged + maskSecondaryFn)

    private func handleGlobeKey(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .flagsChanged else { return Unmanaged.passRetained(event) }

        let isFnPressed = event.flags.contains(.maskSecondaryFn)

        if isFnPressed && !isKeyDown {
            isKeyDown = true
            onKeyDown?()
            return nil
        } else if !isFnPressed && isKeyDown {
            isKeyDown = false
            onKeyUp?()
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    // MARK: - Custom Hotkey

    private func handleCustomKey(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keyCode == Int64(settings.customHotkeyKeyCode) else {
            return Unmanaged.passRetained(event)
        }

        // Modifier-Check: nur wenn gespeicherte Modifier gesetzt sind
        if settings.customHotkeyModifiers != 0 {
            let required = CGEventFlags(rawValue: UInt64(settings.customHotkeyModifiers))
                .intersection([.maskShift, .maskControl, .maskAlternate, .maskCommand])
            let actual = event.flags
                .intersection([.maskShift, .maskControl, .maskAlternate, .maskCommand])
            guard actual == required else { return Unmanaged.passRetained(event) }
        }

        if type == .keyDown && !isKeyDown {
            isKeyDown = true
            onKeyDown?()
            return nil
        } else if type == .keyUp && isKeyDown {
            isKeyDown = false
            onKeyUp?()
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    deinit {
        stop()
    }
}
