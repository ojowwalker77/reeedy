import Foundation

// Represents a book with its metadata and a list of chapter titles.
struct Book: Identifiable, Decodable {
    let id: UUID
    let title: String
    let author: String
    let imageName: String
    let chapterTitles: [String] // Changed from a [Chapter] to a [String]

    enum CodingKeys: String, CodingKey {
        case title, author, imageName, chapters = "Chapters" // Map the JSON "Chapters" key
    }

    // Custom decoder to generate a UUID and handle the chapter titles.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decode(String.self, forKey: .author)
        self.imageName = try container.decode(String.self, forKey: .imageName)
        self.chapterTitles = try container.decode([String].self, forKey: .chapters)
    }
}

// Represents a single word with its associated speed modifier.
struct RhythmicWord {
    let word: String
    var speedModifier: Double
}

// Represents a chapter, now containing its title and the loaded words.
struct Chapter: Identifiable {
    let id = UUID()
    var title: String
    var words: [RhythmicWord]
    var lastReadWordIndex: Int? = nil
}