
import SwiftUI

struct MainTabView: View {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var themeManager = ThemeManager()
    
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    var body: some View {
        ZStack {
            TabView {
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "books.vertical")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .background(.regularMaterial)
            
            // Apply the selected themes as an overlay
            ForEach(themeManager.activeOverlays) { theme in
                Rectangle()
                    .fill(theme.overlayColor)
                    .blendMode(theme.blendMode)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .environmentObject(appSettings) // Provide the settings to all child views
        .environmentObject(userProfileManager)
        .environmentObject(themeManager)
        .onAppear {
            themeManager.loadInitialThemes(from: appSettings)
        }
        .onChange(of: appSettings.colorBlindnessThemeID) { _ in
            themeManager.loadInitialThemes(from: appSettings)
        }
        .onChange(of: appSettings.photosensitivityThemeID) { _ in
            themeManager.loadInitialThemes(from: appSettings)
        }
        .onChange(of: differentiateWithoutColor) { newValue in
            let accessibility = AccessibilitySettings(
                differentiateWithoutColor: newValue,
                reduceMotion: reduceMotion,
                reduceTransparency: reduceTransparency
            )
            themeManager.updateTheme(for: accessibility)
        }
    }
}

#Preview {
    MainTabView()
}
