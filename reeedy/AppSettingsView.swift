import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Default Reading Speed")) {
                    VStack {
                        Text("\(Int(settings.wordsPerMinute)) WPM")
                            .font(.headline)
                        Slider(value: $settings.wordsPerMinute, in: 100...1000, step: 50)
                    }
                    .padding(.vertical)
                }

                Section(header: Text("Default Font Size")) {
                    VStack {
                        Text("Font Size: \(Int(settings.fontSize))")
                            .font(.headline)
                        Slider(value: $settings.fontSize, in: 20...120, step: 5)
                    }
                    .padding(.vertical)
                }

                Section(header: Text("Advanced Settings")) {
                    Toggle("Haptic Feedback", isOn: $settings.hapticFeedbackEnabled)
                    Toggle("Semantic Splitting", isOn: $settings.semanticSplittingEnabled)
                }
            }
            .navigationTitle("App Settings")
        }
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(AppSettings())
}