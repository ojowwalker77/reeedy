import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reading Experience").font(.headline).padding(.top)) {
                    VStack(alignment: .leading, spacing: 15) {
                        Label("Reading Speed", systemImage: "speedometer")
                        Slider(value: $settings.wordsPerMinute, in: 100...1000, step: 50)
                        Text("\(Int(settings.wordsPerMinute)) WPM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        Label("Font Size", systemImage: "textformat.size")
                        Slider(value: $settings.fontSize, in: 20...120, step: 5)
                        Text("\(Int(settings.fontSize))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                Section(header: Text("General").font(.headline)) {
                    Toggle(isOn: $settings.hapticFeedbackEnabled) {
                        Label("Haptic Feedback", systemImage: "iphone.gen3.radiowaves.left.and.right")
                    }
                    Toggle(isOn: $settings.semanticSplittingEnabled) {
                        Label("Semantic Splitting", systemImage: "text.word.spacing")
                    }
                    Toggle(isOn: $settings.drainingCupEnabled) {
                        Label("Draining Cup Timer", systemImage: "hourglass")
                    }
                }

                Section(header: Text("Test Your Settings").font(.headline)) {
                    TestReaderView()
                        .environmentObject(settings)
                }
            }
            .navigationTitle("Settings")
            .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TestReaderView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var testWords: [String] = []
    @State private var currentWordIndex = 0
    @State private var isTesting = false
    @State private var readingTask: Task<Void, Never>?

    let mockText = """
    This is a sample paragraph for you to test the reading speed and font size. You can adjust the settings above and see how they feel in this preview.
    Here is a second paragraph to give you a better sense of the flow. The quick brown fox jumps over the lazy dog. Happy reading!
    """

    var body: some View {
        VStack {
            if isTesting && !testWords.isEmpty {
                Text(testWords[currentWordIndex])
                    .font(.system(size: CGFloat(settings.fontSize)))
                    .frame(height: 100)
                    .id("test_word_\(currentWordIndex)")
                    .transition(.opacity.animation(.easeInOut(duration: 0.1)))
            } else {
                Text("Press 'Start Test' to preview your settings.")
                    .font(.system(size: CGFloat(settings.fontSize) * 0.75))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(height: 100)
            }

            Button(action: {
                if isTesting {
                    stopTest()
                } else {
                    startTest()
                }
            }) {
                Text(isTesting ? "Stop Test" : "Start Test")
                    .fontWeight(.bold)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(isTesting ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear(perform: setupTest)
        .onChange(of: settings.wordsPerMinute) { _, _ in if isTesting { restartTest() } }
        .onChange(of: settings.fontSize) { _, _ in if isTesting { restartTest() } }
    }

    private func setupTest() {
        testWords = mockText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }

    private func startTest() {
        currentWordIndex = 0
        isTesting = true
        readingTask = Task {
            while isTesting && currentWordIndex < testWords.count - 1 {
                let interval = 60.0 / settings.wordsPerMinute
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                } catch {
                    break 
                }
                
                if !isTesting { break }

                withAnimation {
                    currentWordIndex += 1
                }
            }
            if currentWordIndex >= testWords.count - 1 {
                isTesting = false
            }
        }
    }

    private func stopTest() {
        isTesting = false
        readingTask?.cancel()
        readingTask = nil
    }
    
    private func restartTest() {
        stopTest()
        startTest()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
}