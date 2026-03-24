import SwiftUI
import AVFoundation
import ApplicationServices

struct OnboardingView: View {
    @State private var hasMic: Bool = false
    @State private var hasAX:  Bool = false

    private let pollTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var allGranted: Bool { hasMic && hasAX }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            VStack(spacing: 10) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.blue.gradient)

                Text("Willkommen bei Vox")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Vox benötigt zwei Berechtigungen,\num loszulegen.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)

            // MARK: Permission Rows
            VStack(spacing: 12) {
                OnboardingRow(
                    icon: "mic.fill",
                    iconColor: .red,
                    title: "Mikrofon",
                    description: "Für Sprachaufnahmen erforderlich.",
                    isGranted: hasMic,
                    buttonLabel: "Zugriff erlauben"
                ) {
                    AVCaptureDevice.requestAccess(for: .audio) { granted in
                        DispatchQueue.main.async { hasMic = granted }
                    }
                }

                OnboardingRow(
                    icon: "hand.raised.fill",
                    iconColor: .blue,
                    title: "Bedienungshilfen",
                    description: "Für globale Tastenkürzel (Globe-Taste) und Text-Einfügung.",
                    isGranted: hasAX,
                    buttonLabel: "In Einstellungen öffnen"
                ) {
                    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                    AXIsProcessTrustedWithOptions(opts)
                }
            }
            .padding(.horizontal, 32)

            // MARK: Footer
            VStack(spacing: 10) {
                Button {
                    NSApp.keyWindow?.close()
                    NSApp.deactivate()
                } label: {
                    Text(allGranted ? "Loslegen" : "Warte auf Berechtigungen…")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!allGranted)

                Button("Beenden") { NSApp.terminate(nil) }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .frame(width: 460)
        .onAppear   { checkPermissions() }
        .onReceive(pollTimer) { _ in checkPermissions() }
    }

    private func checkPermissions() {
        hasMic = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        hasAX  = AXIsProcessTrusted()
    }
}

// MARK: - OnboardingRow

private struct OnboardingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isGranted: Bool
    let buttonLabel: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isGranted {
                Label("Erlaubt", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.callout)
                    .fontWeight(.medium)
            } else {
                Button(buttonLabel, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(14)
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isGranted ? Color.green.opacity(0.4) : Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingView()
}
