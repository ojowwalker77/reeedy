
import Foundation

// Represents a single word with its associated speed modifier.
struct RhythmicWord: Codable, Hashable {
    let word: String
    var speedModifier: Double
}

struct TimedWord: Codable, Hashable {
    let word: String
    let start: Double
    let end: Double
}

struct ChapterImage: Codable, Hashable {
    let imageName: String
    let startTime: TimeInterval
    let endTime: TimeInterval
}

struct Chapter: Identifiable, Codable, Hashable {
    let id = UUID()
    let title: String
    var words: [RhythmicWord]
    var timedWords: [TimedWord]?
    var lastReadWordIndex: Int?
    var chapterImages: [ChapterImage]? // New property
}
