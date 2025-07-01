import Foundation

// Represents a book with its metadata and a list of chapter titles.
struct Book: Identifiable, Decodable {
    let id: UUID
    let title: String
    let author: String
    let imageName: String
    let chapterTitles: [String] // Changed from a [Chapter] to a [String]
    let age: String

    enum CodingKeys: String, CodingKey {
        case title, author, imageName, chapters = "Chapters", age = "Age"
    }

    // Custom decoder to generate a UUID and handle the chapter titles.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decode(String.self, forKey: .author)
        self.imageName = try container.decode(String.self, forKey: .imageName)
        self.chapterTitles = try container.decode([String].self, forKey: .chapters)
        self.age = try container.decode(String.self, forKey: .age)
    }
}

// Represents a single word with its associated speed modifier.
struct RhythmicWord {
    let word: String
    var speedModifier: Double
}

struct TimedWord: Decodable {
    let word: String
    let start: Double
    let end: Double
}

// Represents a chapter, now containing its title and the loaded words.
struct Chapter: Identifiable {
    let id = UUID()
    var title: String
    var words: [RhythmicWord]
    var timedWords: [TimedWord]? = nil // New property for timed words
    var lastReadWordIndex: Int? = nil
}