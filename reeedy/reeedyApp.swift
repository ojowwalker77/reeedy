import SwiftUI

@main
struct reeedyApp: App {
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var appSettings = AppSettings()
    @StateObject private var themeManager = ThemeManager()
    @AppStorage("isOnboarding") var isOnboarding: Bool = true

    var body: some Scene {
        WindowGroup {
            if isOnboarding {
                OnboardingView(isOnboarding: $isOnboarding)
                    .environmentObject(userProfileManager)
                    .environmentObject(appSettings)
                    .environmentObject(themeManager)
            } else {
                NavigationStack {
                    MainTabView()
                }
                .environmentObject(userProfileManager)
                .environmentObject(appSettings)
                .environmentObject(themeManager)
                .preferredColorScheme(.dark)
            }
        }
    }
}