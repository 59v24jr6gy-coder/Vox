import AppKit
import AVFoundation
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {

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

        _ = RecordingDot.shared   // Dot-Singleton starten (beobachtet AppState)

        Task { @MainActor in
            await AppState.shared.initialize()
        }
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
