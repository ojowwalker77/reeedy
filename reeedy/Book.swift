
import Foundation

struct Book: Identifiable, Decodable {
    let id: UUID
    let title: String
    let author: String
    let imageName: String
    var chapters: [Chapter] = []

    enum CodingKeys: String, CodingKey {
        case title, author, imageName
    }

    // Custom initializer for creating a Book instance directly
    init(id: UUID = UUID(), title: String, author: String, imageName: String, chapters: [Chapter] = []) {
        self.id = id
        self.title = title
        self.author = author
        self.imageName = imageName
        self.chapters = chapters
    }

    // Custom initializer to generate a UUID and handle content loading
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decode(String.self, forKey: .author)
        self.imageName = try container.decode(String.self, forKey: .imageName)
    }
}

struct RhythmicWord {
    let word: String
    var speedModifier: Double
}

struct Chapter: Identifiable {
    let id = UUID()
    var title: String
    var words: [RhythmicWord]
    var startWordIndex: Int
}
