import SwiftUI
import LaunchAtLogin

struct GeneralSettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        Form {
            Section("Tastenkürzel") {
                Toggle("Globe-Taste (🌐) verwenden", isOn: $settings.useGlobeKey)

                if !settings.useGlobeKey {
                    HStack {
                        Text("Eigene Taste")
                        Spacer()
                        HotkeyRecorderView()
                    }
                }
            }

            Section("Sprache") {
                Picker("Transkriptions-Sprache", selection: $settings.transcriptionLanguageRaw) {
                    ForEach(TranscriptionLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
            }

            Section("Text-Einfügung") {
                Picker("Methode", selection: $settings.insertionMethodRaw) {
                    ForEach(InsertionMethod.allCases) { method in
                        Text(method.displayName).tag(method.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)

                if settings.insertionMethod == .clipboard {
                    Label(
                        "Der bisherige Zwischenablagen-Inhalt wird nach dem Einfügen automatisch wiederhergestellt.",
                        systemImage: "info.circle"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Section("System") {
                LaunchAtLogin.Toggle("Bei Anmeldung starten")
            }
        }
        .formStyle(.grouped)
    }

}
