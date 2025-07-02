
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
                themes: colorBlindThemes,
                selection: $appSettings.colorBlindnessThemeID
            )
            
            ThemeCategoryView(
                title: appSettings.selectedLanguage == "Portuguese" ? "Fotossensibilidade" : "Photosensitivity",
                themes: photosensitivityThemes,
                selection: $appSettings.photosensitivityThemeID
            )
        }
    }
}

struct ThemeCategoryView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    let title: String
    let themes: [Theme]
    @Binding var selection: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)
            
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
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .font(.title)
                                    }
                                }
                                Text(theme.name)
                                    .font(.caption)
                                    .foregroundColor(.primary)
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
