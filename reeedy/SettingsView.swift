
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            VStack {
                Label("Reading Speed", systemImage: "speedometer")
                    .font(.headline)
                Text("\(Int(settings.wordsPerMinute)) WPM")
                    .font(.title2)
                    .fontWeight(.bold)
                Slider(value: $settings.wordsPerMinute, in: 100...1000, step: 50)
                    .tint(colorScheme == .dark ? .white : .black)
            }

            VStack {
                Label("Font Size", systemImage: "textformat.size")
                    .font(.headline)
                Text("\(Int(settings.fontSize))")
                    .font(.title2)
                    .fontWeight(.bold)
                Slider(value: $settings.fontSize, in: 20...120, step: 5)
                    .tint(colorScheme == .dark ? .white : .black)
            }

            Toggle(isOn: $settings.semanticSplittingEnabled) {
                Label("Semantic Splitting", systemImage: "text.word.spacing")
                    .font(.headline)
            }
            .tint(colorScheme == .dark ? .white : .black)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
        .foregroundColor(colorScheme == .dark ? .white : .black)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SettingsView(
            onDone: {}
        )
        .environmentObject(AppSettings())
    }
}
