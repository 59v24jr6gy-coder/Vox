import AppKit
import SwiftUI

class RecordingOrbWindow {
    static let shared = RecordingOrbWindow()
    private var panel: NSPanel?

    private init() {}

    func show() {
        if panel == nil { createPanel() }
        panel?.orderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let size: CGFloat = 130
        let hosting = NSHostingView(rootView: RecordingOrbView())

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: size, height: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.contentView = hosting
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = false
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        p.ignoresMouseEvents = true

        // Unten mittig, knapp über dem Dock
        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let x = visible.midX - size / 2
            let y = visible.minY + 24
            p.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.panel = p
    }
}
