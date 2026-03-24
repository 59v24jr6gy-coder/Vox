import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        VStack(spacing: 16) {

            // Echte Orb-Vorschau
            ZStack {
                RecordingOrbView()
                    .scaleEffect(0.85)
            }
            .frame(height: 140)
            .clipped()
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Divider().padding(.horizontal, 20)

            // Farbauswahl
            VStack(alignment: .leading, spacing: 10) {
                Text("Farbe wählen")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 20)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(OrbColor.allCases) { color in
                        ColorSwatch(color: color, isSelected: settings.orbColor == color) {
                            settings.orbColor = color
                        }
                    }
                }
                .padding(.horizontal, 20)

                Text(settings.orbColor.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - ColorSwatch

private struct ColorSwatch: View {
    let color: OrbColor
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                // Glow außerhalb des Clips — nicht abgeschnitten
                Circle()
                    .fill(color.primary.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .blur(radius: 9)

                Circle()
                    .fill(color.primary.opacity(0.08))
                    .frame(width: 18, height: 18)
                    .blur(radius: 5)

                // Orb-Kern
                Circle()
                    .fill(RadialGradient(
                        colors: [color.white.opacity(0.4), color.primary.opacity(0.6), color.secondary.opacity(0.8)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 13
                    ))
                    .frame(width: 24, height: 24)

                // Auswahl-Ring
                if isSelected {
                    Circle()
                        .strokeBorder(color.primary, lineWidth: 2)
                        .frame(width: 42, height: 42)
                }
            }
            .frame(width: 54, height: 54)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AppearanceSettingsView()
        .frame(width: 500, height: 420)
}
