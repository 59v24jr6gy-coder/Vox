import SwiftUI

@main
struct VoxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            // Eigene View isoliert den @ObservedObject vom App-Struct
            // → Settings-Fenster schließt sich nicht mehr bei jedem AppState-Update
            MenuBarIconView()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

// MARK: - MenuBarIconView

struct MenuBarIconView: View {
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.monochrome)
    }

    private var iconName: String {
        switch appState.recordingState {
        case .idle:
            return appState.hasAccessibility ? "mic" : "mic.slash"
        case .recording:
            return "mic.fill"
        case .transcribing:
            return "waveform"
        case .error:
            return "mic.slash"
        }
    }
}
