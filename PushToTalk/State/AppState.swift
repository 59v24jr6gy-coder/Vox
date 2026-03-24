import Foundation
import SwiftUI
import Combine
import ApplicationServices

// MARK: - RecordingState

enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case error(String)

    var statusText: String {
        switch self {
        case .idle:         return "Bereit"
        case .recording:    return "Aufnahme läuft…"
        case .transcribing: return "Transkribiere…"
        case .error(let m): return "Fehler: \(m)"
        }
    }

    var statusColor: Color {
        switch self {
        case .idle:         return .secondary
        case .recording:    return .red
        case .transcribing: return .orange
        case .error:        return .red
        }
    }
}

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var recordingState: RecordingState = .idle
    @Published var lastTranscription: String = ""
    @Published var audioLevel: Float = 0.0
    @Published var isModelLoaded: Bool = false
    @Published var modelLoadingProgress: Double = 0.0
    @Published var isModelLoading: Bool = false
    @Published var hasAccessibility: Bool = false

    let audioRecorder       = AudioRecorder()
    let transcriptionEngine = TranscriptionEngine()
    let hotkeyManager       = HotkeyManager()
    let textInserter        = TextInserter()
    let settings            = SettingsStore.shared

    private var cancellables  = Set<AnyCancellable>()
    private var accessibilityTimer: Timer?
    private var isInitialized = false

    private init() {
        audioRecorder.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$audioLevel)

        $recordingState
            .receive(on: DispatchQueue.main)
            .sink { state in
                if state == .recording {
                    RecordingOrbWindow.shared.show()
                } else {
                    RecordingOrbWindow.shared.hide()
                }
            }
            .store(in: &cancellables)

        hotkeyManager.onKeyDown = { [weak self] in
            Task { @MainActor in await self?.startRecording() }
        }
        hotkeyManager.onKeyUp = { [weak self] in
            Task { @MainActor in await self?.stopRecordingAndTranscribe() }
        }
    }

    // MARK: - Initialisation (nur einmal)

    func initialize() async {
        guard !isInitialized else { return }
        isInitialized = true

        startAccessibilityMonitor()
        await loadCurrentModel()
    }

    // MARK: - Accessibility Monitor

    private func startAccessibilityMonitor() {
        checkAndRestartHotkeyIfNeeded()
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkAndRestartHotkeyIfNeeded() }
        }
    }

    private func checkAndRestartHotkeyIfNeeded() {
        let trusted = AXIsProcessTrusted()
        let wasGranted = hasAccessibility
        hasAccessibility = trusted

        guard trusted else { return }

        if !wasGranted {
            // Accessibility gerade gewährt
            print("[AppState] Accessibility gewährt — starte HotkeyManager")
            hotkeyManager.stop()
            hotkeyManager.start()
        } else if !hotkeyManager.isRunning {
            // Tap war aus irgendeinem Grund nicht aktiv
            print("[AppState] HotkeyManager neu starten")
            hotkeyManager.start()
        }
    }

    // MARK: - Model Management

    func loadCurrentModel() async {
        guard !isModelLoading else { return }
        guard !isModelLoaded || transcriptionEngine.currentModel != settings.selectedModel else { return }

        isModelLoading   = true
        isModelLoaded    = false
        modelLoadingProgress = 0.0

        do {
            try await transcriptionEngine.loadModel(settings.selectedModel) { [weak self] progress in
                Task { @MainActor in self?.modelLoadingProgress = progress }
            }
            isModelLoaded        = true
            modelLoadingProgress = 1.0
        } catch {
            recordingState = .error(error.localizedDescription)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                self?.clearError()
            }
        }

        isModelLoading = false
    }

    func switchModel(to model: WhisperModel) async {
        guard recordingState == .idle else { return }
        settings.selectedModel = model
        isModelLoaded = false
        await loadCurrentModel()
    }

    // MARK: - Recording Flow

    func startRecording() async {
        guard recordingState == .idle else { return }
        guard isModelLoaded else {
            recordingState = .error("Modell noch nicht geladen")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.clearError() }
            return
        }

        do {
            try audioRecorder.startRecording()
            recordingState = .recording
        } catch {
            recordingState = .error(error.localizedDescription)
        }
    }

    func stopRecordingAndTranscribe() async {
        guard recordingState == .recording else { return }
        recordingState = .transcribing

        guard let audioURL = audioRecorder.stopRecording() else {
            recordingState = .idle
            return
        }

        guard audioRecorder.lastRecordingDuration >= 0.1 else {
            try? FileManager.default.removeItem(at: audioURL)
            recordingState = .idle
            return
        }

        do {
            let text = try await transcriptionEngine.transcribe(
                audioURL: audioURL,
                language: settings.transcriptionLanguage
            )
            try? FileManager.default.removeItem(at: audioURL)

            if !text.isEmpty {
                lastTranscription = text
                textInserter.insert(text: text, method: settings.insertionMethod)
            }
            recordingState = .idle

        } catch {
            try? FileManager.default.removeItem(at: audioURL)
            recordingState = .error(error.localizedDescription)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in self?.clearError() }
        }
    }

    func clearError() {
        if case .error = recordingState { recordingState = .idle }
    }
}
