
import SwiftUI

enum ThemeCategory: String {
    case general = "General"
    case colorBlindness = "Color Blindness"
    case photosensitivity = "Photosensitivity"
}

struct Theme: Identifiable, Hashable {
    let id: String
    let name: String
    let overlayColor: Color
    let blendMode: BlendMode
    let category: ThemeCategory
    
    // Accessibility properties
    var isHighContrast: Bool = false
    var reduceMotion: Bool = false
    
    static let defaultTheme = Theme(id: "default", name: "Default", overlayColor: .clear, blendMode: .normal, category: .general)
    
    // High-contrast theme
    static let highContrastTheme = Theme(
        id: "highContrast",
        name: "High Contrast",
        overlayColor: .clear, // No color overlay needed
        blendMode: .normal,
        category: .general,
        isHighContrast: true
    )
}
