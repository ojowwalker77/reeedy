import SwiftUI

@main
struct reeedyApp: App {
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(userProfileManager)
                .environmentObject(appSettings)
        }
    }
}