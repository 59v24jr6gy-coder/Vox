import Foundation
import WhisperKit

class TranscriptionEngine: ObservableObject {
    @Published var isLoading = false

    private(set) var currentModel: WhisperModel?
    private var whisperKit: WhisperKit?

    // WhisperKit lädt in ~/Library/Application Support/Vox/Models/
    static let downloadBase: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let newBase = appSupport.appendingPathComponent("Vox/Models", isDirectory: true)
        // Einmalige Migration von PushToTalk/Models → Vox/Models
        let oldBase = appSupport.appendingPathComponent("PushToTalk/Models", isDirectory: true)
        if FileManager.default.fileExists(atPath: oldBase.path),
           !FileManager.default.fileExists(atPath: newBase.path) {
            try? FileManager.default.createDirectory(at: newBase.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? FileManager.default.moveItem(at: oldBase, to: newBase)
        }
        return newBase
    }()

    // MARK: - Model Loading

    func loadModel(_ model: WhisperModel, progressHandler: @escaping (Double) -> Void) async throws {
        guard currentModel != model else {
            print("[TranscriptionEngine] Modell bereits geladen: \(model.displayName)")
            return
        }

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }

        try FileManager.default.createDirectory(
            at: Self.downloadBase,
            withIntermediateDirectories: true
        )

        print("[TranscriptionEngine] Starte Download/Laden: \(model.rawValue)")
        progressHandler(0.02)

        // Schritt 1: Download mit echtem Fortschritt
        let modelFolder = try await WhisperKit.download(
            variant: model.rawValue,
            downloadBase: Self.downloadBase,
            progressCallback: { progress in
                // fractionCompleted: 0…1, aber Download ist ~80% der Gesamtarbeit
                let normalized = min(0.8, progress.fractionCompleted * 0.8)
                progressHandler(normalized)
            }
        )
        progressHandler(0.82)
        print("[TranscriptionEngine] Download abgeschlossen: \(modelFolder.path)")

        // Schritt 2: Modell aus heruntergeladenem Folder laden
        let config = WhisperKitConfig(
            modelFolder: modelFolder.path,
            computeOptions: ModelComputeOptions(
                melCompute: .cpuAndNeuralEngine,
                audioEncoderCompute: .cpuAndNeuralEngine,
                textDecoderCompute: .cpuAndNeuralEngine
            ),
            verbose: false,
            logLevel: .error,
            prewarm: false,
            load: true,
            download: false   // bereits heruntergeladen
        )

        let kit = try await WhisperKit(config)
        progressHandler(1.0)

        self.whisperKit = kit
        self.currentModel = model
        print("[TranscriptionEngine] Modell geladen: \(model.displayName)")
    }

    // MARK: - Transcription

    func transcribe(audioURL: URL, language: TranscriptionLanguage) async throws -> String {
        guard let whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        print("[TranscriptionEngine] Starte Transkription: \(audioURL.lastPathComponent)")

        let decodingOptions = DecodingOptions(
            task: .transcribe,
            language: language.whisperCode,
            skipSpecialTokens: true,
            withoutTimestamps: true,
            chunkingStrategy: .vad
        )

        let results = try await whisperKit.transcribe(
            audioPath: audioURL.path,
            decodeOptions: decodingOptions
        )

        let text = results
            .map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        print("[TranscriptionEngine] Ergebnis: \"\(text)\"")
        return text
    }

    // MARK: - Cached Models

    static func cachedModelNames() -> [WhisperModel] {
        WhisperModel.allCases.filter { model in
            // WhisperKit legt Modelle in downloadBase/argmaxinc/whisperkit-coreml/openai_whisper-<variant>/ ab
            let searchPath = downloadBase.appendingPathComponent("argmaxinc/whisperkit-coreml")
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: searchPath.path) else {
                return false
            }
            return contents.contains { $0.contains(model.rawValue) }
        }
    }
}

// MARK: - TranscriptionError

enum TranscriptionError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        "Kein Whisper-Modell geladen. Bitte in den Einstellungen ein Modell auswählen."
    }
}
