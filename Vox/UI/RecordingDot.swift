import AppKit
import QuartzCore
import Combine

// Einfache Brücke — wird von RecordingDot geschrieben, von DotView gelesen
private var _dotAudioLevel: Float = 0

// ============================================================
// MARK: - DotTheme  ← Farbsets definieren
// ============================================================
struct DotTheme: Identifiable, Equatable {
    let id:         String
    let name:       String
    let colorOuter: NSColor
    let colorMid:   NSColor
    let colorInner: NSColor
    let colorCore:  NSColor

    static let all: [DotTheme] = [ocean, neonPink, smaragd, lava, aurora, plasma, sunset, titanium]

    static let ocean = DotTheme(
        id:         "ocean",
        name:       "Ozean Blau",
        colorOuter: NSColor(red: 0.05, green: 0.10, blue: 0.80, alpha: 1.00),
        colorMid:   NSColor(red: 0.00, green: 0.30, blue: 1.00, alpha: 1.00),
        colorInner: NSColor(red: 0.10, green: 0.60, blue: 1.00, alpha: 1.00),
        colorCore:  NSColor(red: 0.40, green: 0.85, blue: 1.00, alpha: 1.00)
    )

    static let aurora = DotTheme(
        id:         "perle",
        name:       "Perle",
        colorOuter: NSColor(red: 0.85, green: 0.72, blue: 0.45, alpha: 1.00),
        colorMid:   NSColor(red: 0.95, green: 0.88, blue: 0.68, alpha: 1.00),
        colorInner: NSColor(red: 0.99, green: 0.97, blue: 0.90, alpha: 1.00),
        colorCore:  NSColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.00)
    )

    static let plasma = DotTheme(
        id:         "plasma",
        name:       "Plasma",
        colorOuter: NSColor(red: 0.13, green: 0.00, blue: 0.67, alpha: 1.00),
        colorMid:   NSColor(red: 0.47, green: 0.00, blue: 1.00, alpha: 1.00),
        colorInner: NSColor(red: 0.73, green: 0.40, blue: 1.00, alpha: 1.00),
        colorCore:  NSColor(red: 0.93, green: 0.87, blue: 1.00, alpha: 1.00)
    )

    static let lava = DotTheme(
        id:         "lava",
        name:       "Lava",
        colorOuter: NSColor(red: 0.67, green: 0.07, blue: 0.00, alpha: 1.00),
        colorMid:   NSColor(red: 1.00, green: 0.33, blue: 0.00, alpha: 1.00),
        colorInner: NSColor(red: 1.00, green: 0.80, blue: 0.00, alpha: 1.00),
        colorCore:  NSColor(red: 1.00, green: 0.93, blue: 0.67, alpha: 1.00)
    )

    static let smaragd = DotTheme(
        id:         "smaragd",
        name:       "Smaragd",
        colorOuter: NSColor(red: 0.00, green: 0.27, blue: 0.13, alpha: 1.00),
        colorMid:   NSColor(red: 0.00, green: 0.67, blue: 0.27, alpha: 1.00),
        colorInner: NSColor(red: 0.00, green: 1.00, blue: 0.53, alpha: 1.00),
        colorCore:  NSColor(red: 0.67, green: 1.00, blue: 0.80, alpha: 1.00)
    )

    static let neonPink = DotTheme(
        id:         "neonPink",
        name:       "Neon Pink",
        colorOuter: NSColor(red: 0.53, green: 0.00, blue: 0.27, alpha: 1.00),
        colorMid:   NSColor(red: 1.00, green: 0.00, blue: 0.53, alpha: 1.00),
        colorInner: NSColor(red: 1.00, green: 0.53, blue: 0.80, alpha: 1.00),
        colorCore:  NSColor(red: 1.00, green: 0.87, blue: 0.93, alpha: 1.00)
    )

    static let sunset = DotTheme(
        id:         "sunset",
        name:       "Eis",
        colorOuter: NSColor(red: 0.20, green: 0.33, blue: 0.53, alpha: 1.00),
        colorMid:   NSColor(red: 0.40, green: 0.65, blue: 0.90, alpha: 1.00),
        colorInner: NSColor(red: 0.75, green: 0.90, blue: 1.00, alpha: 1.00),
        colorCore:  NSColor(red: 0.95, green: 0.98, blue: 1.00, alpha: 1.00)
    )

    static let titanium = DotTheme(
        id:         "titanium",
        name:       "Titanium",
        colorOuter: NSColor(red: 0.07, green: 0.07, blue: 0.20, alpha: 1.00),
        colorMid:   NSColor(red: 0.27, green: 0.33, blue: 0.67, alpha: 1.00),
        colorInner: NSColor(red: 0.60, green: 0.67, blue: 0.80, alpha: 1.00),
        colorCore:  NSColor(red: 0.93, green: 0.94, blue: 1.00, alpha: 1.00)
    )
}

// ============================================================
// MARK: - DotConfig  ← Größen & Animation bearbeiten
// ============================================================
enum DotConfig {
    static let windowSize:      CGFloat        = 200
    static let coreRadius:      CGFloat        =  25
    static let coreGlowRadius:  CGFloat        =  20
    static let coreGlowOpacity: Float          = 0.9
    static let breatheScale:    CGFloat        = 1.15
    static let breatheDuration: CFTimeInterval = 0.65
    static let bottomOffset:    CGFloat        = -55

    // ← EXPERIMENT: true = audio-reaktiv, false = statisches Atmen
    static let audioReactiveBreathing: Bool = false
    static let audioSmoothing: Float        = 0.2    // 0 = träge, 1 = sofort
}

// ============================================================
// MARK: - DotView  (wiederverwendbar in Settings-Preview)
// ============================================================
final class DotView: NSView {

    private let theme:    DotTheme
    private let animated: Bool

    private var coreLayer:          CALayer?
    private var smoothedAudioLevel: Float = 0.0
    private var idlePhase:          Double = 0.0
    private var audioTimer:         Timer?

    init(frame: NSRect, theme: DotTheme, animated: Bool = true) {
        self.theme    = theme
        self.animated = animated
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = nil
        layer?.isOpaque = false
        layer?.masksToBounds = false
    }
    required init?(coder: NSCoder) { fatalError() }

    override var isOpaque: Bool { false }

    override func makeBackingLayer() -> CALayer {
        let l = CALayer()
        l.backgroundColor = nil
        l.isOpaque = false
        return l
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil, layer?.sublayers == nil {
            buildLayers()
        }
        if window != nil && animated && DotConfig.audioReactiveBreathing {
            startAudioReactivity()
        } else if window == nil {
            stopAudioReactivity()
        }
    }

    // MARK: - Layer-Aufbau

    private func buildLayers() {
        let c = CGPoint(x: bounds.midX, y: bounds.midY)
        let r = DotConfig.coreRadius

        guard let img = makeRadialGradientImage(radius: r, theme: theme) else { return }

        let core = CALayer()
        core.contents      = img
        core.frame         = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
        core.shadowColor   = theme.colorMid.cgColor
        core.shadowRadius  = DotConfig.coreGlowRadius
        core.shadowOpacity = DotConfig.coreGlowOpacity
        core.shadowOffset  = .zero
        core.masksToBounds = false
        layer?.addSublayer(core)
        coreLayer = core

        if animated && !DotConfig.audioReactiveBreathing {
            // Statisches Atmen (alter Modus)
            let breathe = CABasicAnimation(keyPath: "transform.scale")
            breathe.fromValue      = 1.0
            breathe.toValue        = DotConfig.breatheScale
            breathe.duration       = DotConfig.breatheDuration
            breathe.autoreverses   = true
            breathe.repeatCount    = .infinity
            breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            core.add(breathe, forKey: "breathe")
        }
    }

    // MARK: - Audio-Reaktivität

    private func startAudioReactivity() {
        guard audioTimer == nil else { return }
        audioTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopAudioReactivity() {
        audioTimer?.invalidate()
        audioTimer = nil
    }

    private func tick() {
        smoothedAudioLevel = smoothedAudioLevel * (1 - DotConfig.audioSmoothing)
                           + _dotAudioLevel      * DotConfig.audioSmoothing

        // Idle-Puls: sanfte Sinus-Welle immer aktiv (0 → 0.05)
        idlePhase += (1.0 / 60.0) / DotConfig.breatheDuration * .pi
        let idle  = CGFloat(0.5 + 0.5 * sin(idlePhase)) * 0.05

        // Audio addiert darüber (0 → ~0.4 bei voller Lautstärke)
        let audio = CGFloat(smoothedAudioLevel) * 0.4

        let s = 1.0 + idle + audio
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        coreLayer?.transform = CATransform3DMakeScale(s, s, 1)
        CATransaction.commit()
    }

    // MARK: - Radialer Farbverlauf

    static func makeRadialGradientImage(radius: CGFloat, theme: DotTheme) -> CGImage? {
        let size = Int(radius * 2)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let colors = [theme.colorCore.cgColor,
                      theme.colorInner.cgColor,
                      theme.colorMid.cgColor,
                      theme.colorOuter.cgColor,
                      theme.colorOuter.withAlphaComponent(0).cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 0.25, 0.55, 0.82, 1.0]

        guard let gradient = CGGradient(colorsSpace: colorSpace,
                                        colors: colors,
                                        locations: locations) else { return nil }
        let center = CGPoint(x: radius, y: radius)
        ctx.drawRadialGradient(gradient,
                               startCenter: center, startRadius: 0,
                               endCenter: center, endRadius: radius,
                               options: [])
        return ctx.makeImage()
    }

    private func makeRadialGradientImage(radius: CGFloat, theme: DotTheme) -> CGImage? {
        DotView.makeRadialGradientImage(radius: radius, theme: theme)
    }
}

// ============================================================
// MARK: - RecordingDot  (Singleton – show / hide)
// ============================================================
final class RecordingDot {
    static let shared = RecordingDot()

    private var panel:              NSPanel?
    private var stateCancellable:   AnyCancellable?
    private var audioCancellable:   AnyCancellable?

    private init() {
        DispatchQueue.main.async { [weak self] in
            self?.stateCancellable = AppState.shared.$recordingState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    if case .recording = state { self?.show() } else { self?.hide() }
                }
            self?.audioCancellable = AppState.shared.$audioLevel
                .receive(on: DispatchQueue.main)
                .sink { level in _dotAudioLevel = level }
        }
    }

    private func show() {
        if let p = panel { p.orderFrontRegardless(); return }

        guard let screen = NSScreen.main else { return }
        let size  = DotConfig.windowSize
        let x     = screen.frame.midX - size / 2
        let y     = screen.visibleFrame.minY + DotConfig.bottomOffset
        let theme = DotTheme.all.first(where: { $0.id == AppState.shared.settings.dotThemeID })
                    ?? DotTheme.ocean

        let p = NSPanel(
            contentRect: NSRect(x: x, y: y, width: size, height: size),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        p.isOpaque           = false
        p.backgroundColor    = .clear
        p.hasShadow          = false
        p.ignoresMouseEvents = true
        p.level              = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        p.contentView        = DotView(frame: NSRect(x: 0, y: 0, width: size, height: size),
                                       theme: theme)
        panel = p
        p.orderFrontRegardless()
    }

    private func hide() {
        panel?.orderOut(nil)
        panel = nil
    }
}
