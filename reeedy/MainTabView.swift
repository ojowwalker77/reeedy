
import SwiftUI

struct MainTabView: View {
    @StateObject private var appSettings = AppSettings()

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
        }
        .environmentObject(appSettings) // Provide the settings to all child views
    }
}

#Preview {
    MainTabView()
}
