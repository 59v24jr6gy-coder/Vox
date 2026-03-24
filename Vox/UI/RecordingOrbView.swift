import SwiftUI

// MARK: - RecordingOrbView

struct RecordingOrbView: View {
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        let color = settings.orbColor
        ZStack {
            PulseRing(primary: color.primary, baseSize: 50, delay: 0.0)
            PulseRing(primary: color.primary, baseSize: 50, delay: 0.6)
            PulseRing(primary: color.primary, baseSize: 50, delay: 1.2)
            OrbCore(primary: color.primary, secondary: color.secondary, white: color.white)
        }
        .frame(width: 130, height: 130)
    }
}

// MARK: - PulseRing

private struct PulseRing: View {
    let primary: Color
    let baseSize: CGFloat
    let delay: Double

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .stroke(primary, lineWidth: isAnimating ? 0.5 : 2.0)
            .frame(width: baseSize, height: baseSize)
            .scaleEffect(isAnimating ? 2.4 : 1.0)
            .opacity(isAnimating ? 0 : 0.85)
            .shadow(color: primary, radius: 6)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
            }
    }
}

// MARK: - OrbCore

private struct OrbCore: View {
    let primary: Color
    let secondary: Color
    let white: Color

    @State private var breathe: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [white, primary, secondary],
                    center: .center,
                    startRadius: 0,
                    endRadius: 18
                ))
                .frame(width: 44, height: 44)

            Circle()
                .fill(RadialGradient(
                    colors: [.white.opacity(0.5), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 20
                ))
                .frame(width: 44, height: 44)
        }
        .scaleEffect(breathe ? 1.08 : 0.93)
        .shadow(color: .white.opacity(0.8),     radius: 3)
        .shadow(color: primary,                  radius: 8)
        .shadow(color: primary.opacity(0.8),     radius: 16)
        .shadow(color: primary.opacity(0.5),     radius: 28)
        .shadow(color: secondary.opacity(0.3),   radius: 42)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

#Preview {
    RecordingOrbView()
        .frame(width: 180, height: 180)
        .background(Color.black)
}
