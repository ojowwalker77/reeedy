import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var themeManager: ThemeManager
    
    private var colorBlindThemes: [Theme] {
        themeManager.themes.filter { $0.category == .colorBlindness }
    }
    
    private var photosensitivityThemes: [Theme] {
        themeManager.themes.filter { $0.category == .photosensitivity }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ThemeCategoryView(
                title: appSettings.selectedLanguage == "Portuguese" ? "Daltonismo" : "Color Blindness",
                description: appSettings.selectedLanguage == "Portuguese" ? "Temas otimizados para diferentes tipos de daltonismo." : "Themes optimized for various types of color blindness.",
                themes: colorBlindThemes,
                selection: $appSettings.colorBlindnessThemeID
            )
            
            ThemeCategoryView(
                title: appSettings.selectedLanguage == "Portuguese" ? "Fotossensibilidade" : "Photosensitivity",
                description: appSettings.selectedLanguage == "Portuguese" ? "Temas com cores e contrastes que podem ajudar a reduzir a sensibilidade à luz." : "Themes with colors and contrasts that may help reduce light sensitivity.",
                themes: photosensitivityThemes,
                selection: $appSettings.photosensitivityThemeID
            )
        }
    }
}

struct ThemeCategoryView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    let title: String
    let description: String
    let themes: [Theme]
    @Binding var selection: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(appSettings.selectedFont.font(size: 17, weight: .bold))
                .padding(.bottom, 2)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Text(description)
                .font(appSettings.selectedFont.font(size: 14))
                .foregroundColor(.gray)
                .padding(.bottom, 10)
                .minimumScaleFactor(0.5)
                .lineLimit(2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(themes) { theme in
                        Button(action: {
                            if selection == theme.id {
                                selection = ""
                            } else {
                                selection = theme.id
                            }
                        }) {
                            VStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                    
                                    // Simulate a preview of the theme
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(theme.overlayColor)
                                        .blendMode(theme.blendMode)
                                        .frame(width: 100, height: 100)
                                    
                                    if selection == theme.id {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.accentColor, lineWidth: 3)
                                            .frame(width: 100, height: 100)
                                    }
                                }
                                Text(theme.name)
                                    .font(appSettings.selectedFont.font(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ThemePickerView_Previews: PreviewProvider {
    static var previews: some View {
        ThemePickerView()
            .environmentObject(AppSettings())
            .environmentObject(ThemeManager())
    }
}
