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

Section("System") {
                LaunchAtLogin.Toggle("Bei Anmeldung starten")
            }
        }
        .formStyle(.grouped)
    }

}
