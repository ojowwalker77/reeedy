
import SwiftUI

class ThemeManager: ObservableObject {
    @Published var themes: [Theme] = [
        .defaultTheme,
        Theme(id: "soften", name: "Soften Brightness", overlayColor: Color.black.opacity(0.2), blendMode: .multiply, category: .photosensitivity),
        Theme(id: "protanopia", name: "Protanopia", overlayColor: Color(red: 0, green: 0.6, blue: 0.8), blendMode: .multiply, category: .colorBlindness),
        Theme(id: "deuteranopia", name: "Deuteranopia", overlayColor: Color(red: 0.6, green: 0, blue: 0.8), blendMode: .multiply, category: .colorBlindness),
        Theme(id: "tritanopia", name: "Tritanopia", overlayColor: Color(red: 0.8, green: 0.4, blue: 0), blendMode: .multiply, category: .colorBlindness),
        Theme(id: "achromatopsia", name: "Achromatopsia", overlayColor: .gray, blendMode: .color, category: .colorBlindness),
        .highContrastTheme // Add the high-contrast theme
    ]
    
    @Published var selectedColorBlindnessTheme: Theme? = nil
    @Published var selectedPhotosensitivityTheme: Theme? = nil
    
    init() { }
    
    func loadInitialThemes(from appSettings: AppSettings) {
        selectedColorBlindnessTheme = appSettings.colorBlindnessThemeID.isEmpty ? nil : themes.first { $0.id == appSettings.colorBlindnessThemeID }
        selectedPhotosensitivityTheme = appSettings.photosensitivityThemeID.isEmpty ? nil : themes.first { $0.id == appSettings.photosensitivityThemeID }
    }
    
    func updateTheme(for accessibility: AccessibilitySettings) {
        if accessibility.differentiateWithoutColor {
            selectedColorBlindnessTheme = .highContrastTheme
        } else {
            // When differentiateWithoutColor is off, the MainTabView will reload the initial themes.
            // No action needed here.
        }
    }
    
    var activeOverlays: [Theme] {
        [selectedColorBlindnessTheme, selectedPhotosensitivityTheme].compactMap { $0 }
    }
}

struct AccessibilitySettings {
    var differentiateWithoutColor: Bool
    var reduceMotion: Bool
    var reduceTransparency: Bool
}
