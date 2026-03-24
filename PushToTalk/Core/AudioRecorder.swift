import Foundation
import AVFoundation
import Combine

class AudioRecorder: ObservableObject {
    @Published var audioLevel: Float = 0.0

    private var audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var outputURL: URL?
    private var recordingStartTime: Date?
    private(set) var lastRecordingDuration: TimeInterval = 0

    private let targetSampleRate: Double = 16_000
    private var levelTimer: Timer?

    // MARK: - Start

    func startRecording() throws {
        audioEngine = AVAudioEngine()

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Target: 16kHz Mono PCM (Whisper-Format)
        guard let monoFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioError.formatCreationFailed
        }

        let url = makeTemporaryURL()
        outputURL = url

        audioFile = try AVAudioFile(forWriting: url, settings: monoFormat.settings)

        // Konverter: native Mikrofon-Format → 16kHz Mono
        guard let converter = AVAudioConverter(from: inputFormat, to: monoFormat) else {
            throw AudioError.converterCreationFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }

            // Level-Metering
            self.updateAudioLevel(from: buffer)

            // Konvertierung
            let frameCapacity = AVAudioFrameCount(
                Double(buffer.frameLength) * self.targetSampleRate / inputFormat.sampleRate
            )
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: frameCapacity) else { return }

            var error: NSError?
            var sourceBufferList = buffer.audioBufferList.pointee
            converter.convert(to: convertedBuffer, error: &error) { _, inputStatus in
                inputStatus.pointee = .haveData
                return buffer
            }

            if let error {
                print("[AudioRecorder] Konvertierungsfehler: \(error)")
                return
            }

            do {
                try self.audioFile?.write(from: convertedBuffer)
            } catch {
                print("[AudioRecorder] Schreibfehler: \(error)")
            }
        }

        try audioEngine.start()
        recordingStartTime = Date()
        print("[AudioRecorder] Aufnahme gestartet: \(url.path)")
    }

    // MARK: - Stop

    @discardableResult
    func stopRecording() -> URL? {
        lastRecordingDuration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioFile = nil
        audioLevel = 0.0
        recordingStartTime = nil

        print("[AudioRecorder] Aufnahme gestoppt. Dauer: \(String(format: "%.2f", lastRecordingDuration))s")
        return outputURL
    }

    // MARK: - Private Helpers

    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrtf(sum / Float(frameLength))
        let db = 20 * log10f(max(rms, 1e-7))
        // Normalisiere –60dB…0dB auf 0…1
        let normalized = max(0, min(1, (db + 60) / 60))
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = normalized
        }
    }

    private func makeTemporaryURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("ptt_recording_\(UUID().uuidString).wav")
    }
}

// MARK: - AudioError

enum AudioError: LocalizedError {
    case formatCreationFailed
    case converterCreationFailed

    var errorDescription: String? {
        switch self {
        case .formatCreationFailed:    return "Audio-Format konnte nicht erstellt werden."
        case .converterCreationFailed: return "Audio-Konverter konnte nicht erstellt werden."
        }
    }
}
