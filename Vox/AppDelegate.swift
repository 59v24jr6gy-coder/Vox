import AppKit
import SwiftUI
import AVFoundation
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellable: Any?

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Single-Instance: alte Instanzen beenden, neue läuft weiter
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        for other in running where other != NSRunningApplication.current {
            other.forceTerminate()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestPermissionsIfNeeded()
        setupStatusItem()

        _ = RecordingDot.shared

        Task { @MainActor in
            await AppState.shared.initialize()
        }
    }

    // MARK: - Status Item + Popover

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item

        if let button = item.button {
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Vox")
            button.action = #selector(togglePopover)
            button.target = self
        }

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 500, height: 500)
        pop.behavior = .transient
        pop.contentViewController = NSHostingController(rootView: MenuBarView())
        popover = pop

        // Icon live aktualisieren wenn sich recordingState ändert
        DispatchQueue.main.async { [weak self] in
            self?.cancellable = AppState.shared.$recordingState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in self?.updateIcon(state: state) }
        }
    }

    @objc private func togglePopover() {
        guard let pop = popover, let button = statusItem?.button else { return }
        if pop.isShown {
            pop.performClose(nil)
        } else {
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            pop.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateIcon(state: RecordingState) {
        guard let button = statusItem?.button else { return }
        let name: String
        switch state {
        case .idle:         name = AXIsProcessTrusted() ? "mic" : "mic.slash"
        case .recording:    name = "mic.fill"
        case .transcribing: name = "waveform"
        case .error:        name = "mic.slash"
        }
        button.image = NSImage(systemSymbolName: name, accessibilityDescription: "Vox")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppState.shared.hotkeyManager.stop()
    }

    // MARK: - Permissions

    private func requestPermissionsIfNeeded() {
        // Mikrofon — zeigt Apple-Systemdialog beim ersten Mal
        if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        }

        // Accessibility — öffnet System-Einstellungen mit Prompt beim ersten Mal
        if !AXIsProcessTrusted() {
            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(opts)
        }
    }
}
