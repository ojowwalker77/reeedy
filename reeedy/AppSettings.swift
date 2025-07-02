
import SwiftUI

enum AppFont: String, CaseIterable, Identifiable {
    case systemRounded = "System Rounded"
    case openDyslexic = "OpenDyslexic"

    var id: String { self.rawValue }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .systemRounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .openDyslexic:
            let fontName = "OpenDyslexic"
            let fontWeight: String
            switch weight {
            case .bold, .semibold, .heavy, .black:
                fontWeight = "-Bold"
            default:
                fontWeight = "-Regular"
            }
            return .custom(fontName + fontWeight, size: size)
        }
    }

    func tag(for language: String) -> (text: String, color: Color) {
        switch self {
        case .systemRounded:
            let tagText = language == "Portuguese" ? "Padrão" : "Default"
            return (tagText, .gray)
        case .openDyslexic:
            let tagText = language == "Portuguese" ? "AMIGÁVEL PARA DISLÉXICOS" : "DYSLEXIC FRIENDLY"
            return (tagText, .accentColor)
        }
    }
}

// This class holds the user's default settings and automatically saves them to UserDefaults using @AppStorage.
class AppSettings: ObservableObject {
    @AppStorage("fontSize") var fontSize: Double = 50.0
    @AppStorage("hapticFeedbackEnabled") var hapticFeedbackEnabled: Bool = true
    @AppStorage("semanticSplittingEnabled") var semanticSplittingEnabled: Bool = true
    @AppStorage("readingSpeed") var readingSpeed: Double = 1.0
    @AppStorage("selectedLanguage") var selectedLanguage: String = "English"
    @AppStorage("colorBlindnessThemeID") var colorBlindnessThemeID: String = ""
    @AppStorage("photosensitivityThemeID") var photosensitivityThemeID: String = ""
    @AppStorage("reduceMotion") var reduceMotion: Bool = false
    @AppStorage("reduceTransparency") var reduceTransparency: Bool = false
    @AppStorage("selectedFont") var selectedFont: AppFont = .systemRounded

    var dyslexiaFontEnabled: Bool {
        return selectedFont == .openDyslexic
    }
}

