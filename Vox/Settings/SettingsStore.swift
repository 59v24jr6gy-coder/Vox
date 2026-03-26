import Foundation
import SwiftUI

// MARK: - WhisperModel

enum WhisperModel: String, CaseIterable, Identifiable {
    // Kurzname wird direkt als variant an WhisperKit.download() übergeben
    case tiny   = "tiny"
    case base   = "base"
    case small  = "small"
    case medium = "medium"
    case large  = "large-v3"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tiny:   return "Tiny"
        case .base:   return "Base"
        case .small:  return "Small"
        case .medium: return "Medium"
        case .large:  return "Large v3"
        }
    }

    var sizeDescription: String {
        switch self {
        case .tiny:   return "~150 MB"
        case .base:   return "~290 MB"
        case .small:  return "~490 MB"
        case .medium: return "~1.5 GB"
        case .large:  return "~3 GB"
        }
    }

    var qualityDescription: String {
        switch self {
        case .tiny:   return "Schnell, weniger genau"
        case .base:   return "Schnell, gute Basisqualität"
        case .small:  return "Gute Balance"
        case .medium: return "Empfohlen – hohe Genauigkeit"
        case .large:  return "Beste Qualität, langsamer"
        }
    }
}

// MARK: - InsertionMethod

enum InsertionMethod: String, CaseIterable, Identifiable {
    case axAPI     = "axAPI"
    case clipboard = "clipboard"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .axAPI:     return "AX API (nativ)"
        case .clipboard: return "Zwischenablage (Fallback)"
        }
    }
}

// MARK: - TranscriptionLanguage

enum TranscriptionLanguage: String, CaseIterable, Identifiable {
    case german  = "de"
    case english = "en"
    case french  = "fr"
    case spanish = "es"
    case auto    = ""

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .german:  return "Deutsch"
        case .english: return "English"
        case .french:  return "Français"
        case .spanish: return "Español"
        case .auto:    return "Automatisch"
        }
    }

    var whisperCode: String? {
        rawValue.isEmpty ? nil : rawValue
    }
}


// MARK: - SettingsStore

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @AppStorage("selectedModel")            var selectedModelRaw: String          = WhisperModel.medium.rawValue
    @AppStorage("transcriptionLanguage")   var transcriptionLanguageRaw: String  = TranscriptionLanguage.german.rawValue
    @AppStorage("insertionMethod")         var insertionMethodRaw: String         = InsertionMethod.axAPI.rawValue
    @AppStorage("launchAtLogin")           var launchAtLogin: Bool                = false
    @AppStorage("useGlobeKey")             var useGlobeKey: Bool                  = true
    @AppStorage("customHotkeyKeyCode")     var customHotkeyKeyCode: Int           = 0
    @AppStorage("customHotkeyModifiers")   var customHotkeyModifiers: Int         = 0
    @AppStorage("dotThemeID")             var dotThemeID: String                  = "ocean"
    var selectedModel: WhisperModel {
        get { WhisperModel(rawValue: selectedModelRaw) ?? .medium }
        set { selectedModelRaw = newValue.rawValue }
    }

    var transcriptionLanguage: TranscriptionLanguage {
        get { TranscriptionLanguage(rawValue: transcriptionLanguageRaw) ?? .german }
        set { transcriptionLanguageRaw = newValue.rawValue }
    }

    var insertionMethod: InsertionMethod {
        get { InsertionMethod(rawValue: insertionMethodRaw) ?? .axAPI }
        set { insertionMethodRaw = newValue.rawValue }
    }
}
