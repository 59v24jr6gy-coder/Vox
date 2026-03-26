import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("Allgemein",        systemImage: "gearshape") }

            ModelSettingsView()
                .tabItem { Label("Modell",           systemImage: "brain.head.profile") }

            DotAppearanceSettingsView()
                .tabItem { Label("Darstellung",       systemImage: "paintpalette.fill") }

            PermissionsSettingsView()
                .tabItem { Label("Berechtigungen",   systemImage: "hand.raised.fill") }
        }
        .frame(width: 500, height: 500)
    }
}

#Preview {
    SettingsView()
}
