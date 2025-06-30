import SwiftUI

// This class holds the user's default settings and automatically saves them to UserDefaults using @AppStorage.
class AppSettings: ObservableObject {
    @AppStorage("wordsPerMinute") var wordsPerMinute: Double = 200.0
    @AppStorage("fontSize") var fontSize: Double = 50.0
    @AppStorage("hapticFeedbackEnabled") var hapticFeedbackEnabled: Bool = true
    @AppStorage("drainingCupEnabled") var drainingCupEnabled: Bool = true
    @AppStorage("semanticSplittingEnabled") var semanticSplittingEnabled: Bool = true
    @AppStorage("lofiMusicEnabled") var lofiMusicEnabled: Bool = false
    @AppStorage("lofiMusicPlaybackTime") var lofiMusicPlaybackTime: Double = 0.0
    @AppStorage("audioReadingEnabled") var audioReadingEnabled: Bool = false
}
