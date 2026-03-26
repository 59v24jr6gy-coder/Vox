import SwiftUI
import AppKit

// ============================================================
// MARK: - DotAppearanceSettingsView
// ============================================================
struct DotAppearanceSettingsView: View {
    @ObservedObject private var settings = AppState.shared.settings

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Live-Vorschau
                VStack(spacing: 6) {
                    Text("Vorschau")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    DotPreview(theme: selectedTheme, animated: true)
                        .id(selectedTheme.id)
                        .frame(width: 150, height: 150)
                        .background(Color.black.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Divider()

                // Theme-Auswahl
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 12) {
                    ForEach(DotTheme.all) { theme in
                        ThemeCard(theme: theme,
                                  isSelected: settings.dotThemeID == theme.id)
                            .onTapGesture { settings.dotThemeID = theme.id }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
    }

    private var selectedTheme: DotTheme {
        DotTheme.all.first(where: { $0.id == settings.dotThemeID }) ?? DotTheme.ocean
    }
}

// ============================================================
// MARK: - ThemeCard
// ============================================================
private struct ThemeCard: View {
    let theme:      DotTheme
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            DotPreview(theme: theme, animated: false)
                .frame(width: 64, height: 64)
                .background(Color.black.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                                      lineWidth: isSelected ? 2 : 1)
                )

            Text(theme.name)
                .font(.caption2)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
    }
}

// ============================================================
// MARK: - DotPreview  (NSViewRepresentable → DotView)
// ============================================================
struct DotPreview: NSViewRepresentable {
    let theme:    DotTheme
    let animated: Bool

    func makeNSView(context: Context) -> DotView {
        DotView(frame: .zero, theme: theme, animated: animated)
    }

    func updateNSView(_ nsView: DotView, context: Context) {}
}
