import SwiftUI

// MARK: - MenuBarView

struct MenuBarView: View {
    @State private var showSettings = false

    var body: some View {
        if showSettings {
            // Erweitertes Einstellungs-Panel
            VStack(spacing: 0) {
                ZStack {
                    Text("Einstellungen")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { showSettings = false }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Zurück")
                            }
                            .font(.callout)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                InlineSettingsTabs()
                    .frame(width: 500, height: 420)
            }
            .transition(.opacity)

        } else {
            // Normales Status-Menü
            StatusMenuView(onSettingsTapped: {
                withAnimation(.easeInOut(duration: 0.2)) { showSettings = true }
            })
            .transition(.opacity)
        }
    }
}

// MARK: - StatusMenuView

private struct StatusMenuView: View {
    @ObservedObject var appState = AppState.shared
    let onSettingsTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: stateIcon)
                    .foregroundColor(appState.recordingState.statusColor)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Vox").font(.headline)
                    Text(appState.recordingState.statusText)
                        .font(.caption).foregroundColor(.secondary)
                }

                Spacer()

                Text(appState.settings.selectedModel.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(4)
            }

            Divider()

            if appState.recordingState == .recording {
                AudioLevelView(level: appState.audioLevel)
                    .frame(height: 20).transition(.opacity)
            }

            if appState.isModelLoading {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lade \(appState.settings.selectedModel.displayName)…")
                        .font(.caption).foregroundColor(.secondary)
                    ProgressView(value: appState.modelLoadingProgress)
                }
            }

            Divider()

            HStack {
                Image(systemName: "keyboard").foregroundColor(.secondary).font(.caption)
                Text(appState.settings.useGlobeKey
                     ? "🌐 Taste gedrückt halten zum Diktieren"
                     : "Benutzerdefinierter Hotkey aktiv")
                    .font(.caption).foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Button("Einstellungen", action: onSettingsTapped)
                    .font(.callout)

                Spacer()

                Button("Beenden") { NSApplication.shared.terminate(nil) }
                    .font(.callout)
            }
        }
        .padding(16)
        .frame(width: 300)
        .animation(.easeInOut(duration: 0.2), value: appState.recordingState)
    }

    private var stateIcon: String {
        switch appState.recordingState {
        case .idle:         return appState.isModelLoaded ? "mic" : "hourglass"
        case .recording:    return "mic.fill"
        case .transcribing: return "waveform"
        case .error:        return "exclamationmark.circle"
        }
    }
}

// MARK: - InlineSettingsTabs

private struct InlineSettingsTabs: View {
    @State private var selected = 0

    private let tabs: [(icon: String, label: String)] = [
        ("gearshape",          "Allgemein"),
        ("brain.head.profile", "Modell"),
        ("paintpalette",       "Darstellung"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Custom Tab Bar
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { i in
                    Button {
                        selected = i
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tabs[i].icon)
                                .font(.system(size: 18))
                            Text(tabs[i].label)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .foregroundColor(selected == i ? .accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 56)

            Divider()

            // Content
            Group {
                switch selected {
                case 0: GeneralSettingsView()
                case 1: ModelSettingsView()
                default: AppearanceSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - AudioLevelView

struct AudioLevelView: View {
    let level: Float
    private let barCount = 20

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { i in
                    let threshold = Float(i) / Float(barCount)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(index: i, active: level > threshold))
                        .frame(width: (geo.size.width - CGFloat(barCount - 1) * 2) / CGFloat(barCount))
                }
            }
        }
    }

    private func barColor(index: Int, active: Bool) -> Color {
        guard active else { return Color.secondary.opacity(0.2) }
        let ratio = Float(index) / Float(barCount)
        if ratio < 0.6 { return .green }
        if ratio < 0.85 { return .yellow }
        return .red
    }
}

#Preview { MenuBarView() }
