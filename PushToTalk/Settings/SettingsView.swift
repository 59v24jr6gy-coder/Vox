import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("Allgemein",   systemImage: "gearshape") }

            ModelSettingsView()
                .tabItem { Label("Modell",      systemImage: "brain.head.profile") }

            AppearanceSettingsView()
                .tabItem { Label("Darstellung", systemImage: "paintpalette") }
        }
        .frame(width: 500, height: 420)
    }
}

#Preview {
    SettingsView()
}
