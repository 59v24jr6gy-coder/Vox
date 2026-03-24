import SwiftUI
import ApplicationServices
import AVFoundation

struct PermissionsSettingsView: View {
    @ObservedObject private var appState = AppState.shared
    @State private var hasMicAccess: Bool = false
    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section {
                PermissionRow(
                    icon: "mic.fill",
                    iconColor: .red,
                    title: "Mikrofon",
                    description: "Für Sprachaufnahmen erforderlich.",
                    isGranted: hasMicAccess,
                    action: requestMicAccess
                )

                PermissionRow(
                    icon: "hand.raised.fill",
                    iconColor: .blue,
                    title: "Bedienungshilfen (Accessibility)",
                    description: "Für globale Tastenkürzel (Globe-Taste) und Text-Einfügung erforderlich.",
                    isGranted: appState.hasAccessibility,
                    action: requestAccessibilityAccess
                )
            } header: {
                Text("Berechtigungen")
            } footer: {
                if !appState.hasAccessibility {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(
                            "Nach dem Aktivieren in System-Einstellungen muss die App neu gestartet werden.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundColor(.orange)
                        .font(.caption)

                        Button("App neu starten") { relaunchApp() }
                            .controlSize(.small)
                    }
                } else if !hasMicAccess {
                    Label(
                        "Mikrofon-Zugriff wird für Aufnahmen benötigt.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundColor(.orange)
                    .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { hasMicAccess = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized }
        .onReceive(timer) { _ in
            hasMicAccess = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        }
    }

    private func requestMicAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async { hasMicAccess = granted }
        }
    }

    private func requestAccessibilityAccess() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }

    private func relaunchApp() {
        let path = Bundle.main.bundleURL.path
        // Shell startet die App 1s nach dem Beenden dieser Instanz
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 1 && open '\(path)'"]
        try? task.run()
        NSApp.terminate(nil)
    }
}

// MARK: - PermissionRow

struct PermissionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isGranted {
                Label("Erlaubt", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.callout)
            } else {
                Button("Erlauben", action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}
