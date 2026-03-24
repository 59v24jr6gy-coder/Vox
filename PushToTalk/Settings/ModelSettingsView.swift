import SwiftUI

struct ModelSettingsView: View {
    @ObservedObject private var appState  = AppState.shared
    @ObservedObject private var settings  = SettingsStore.shared

    var body: some View {
        Form {
            Section {
                ForEach(WhisperModel.allCases) { model in
                    ModelRow(
                        model: model,
                        isSelected: settings.selectedModel == model,
                        isActive: appState.transcriptionEngine.currentModel == model,
                        isLoading: appState.isModelLoading && settings.selectedModel == model,
                        loadingProgress: appState.modelLoadingProgress
                    ) {
                        guard !appState.isModelLoading else { return }
                        Task { await appState.switchModel(to: model) }
                    }
                }
            } header: {
                Text("Whisper-Modell")
            } footer: {
                Text("Modelle werden in ~/Library/Application Support/Vox/Models/ gecacht.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Aktueller Ladevorgang
            if appState.isModelLoading {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Lade \(settings.selectedModel.displayName) (\(settings.selectedModel.sizeDescription))…")
                            .font(.callout)
                        ProgressView(value: appState.modelLoadingProgress)
                        Text("\(Int(appState.modelLoadingProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - ModelRow

struct ModelRow: View {
    let model: WhisperModel
    let isSelected: Bool
    let isActive: Bool
    let isLoading: Bool
    let loadingProgress: Double
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Auswahl-Indikator
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isActive ? .accentColor : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(model.displayName)
                        .fontWeight(isSelected ? .semibold : .regular)
                    if isActive {
                        Text("AKTIV")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .cornerRadius(4)
                    }
                }
                Text(model.qualityDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(model.sizeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if !isActive {
                    Button("Laden") {
                        onSelect()
                    }
                    .controlSize(.small)
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isActive && !isLoading {
                onSelect()
            }
        }
    }
}

#Preview {
    ModelSettingsView()
        .frame(width: 480)
}
