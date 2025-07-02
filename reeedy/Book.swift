import Foundation

// Represents a book with its metadata and a list of chapter titles.
struct Book: Identifiable, Decodable, Hashable {
    let id: UUID
    let title: String
    let author: String
    let imageName: String
    let bookBackground: String
    let chapterTitles: [String] // Changed from a [Chapter] to a [String]
    let age: String
    let language: String

    enum CodingKeys: String, CodingKey {
        case title, author, imageName, bookBackground = "BookBackground", chapters = "Chapters", age = "Age", language = "BookLanguage"
    }

    // Custom decoder to generate a UUID and handle the chapter titles.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decode(String.self, forKey: .author)
        self.imageName = try container.decode(String.self, forKey: .imageName)
        self.bookBackground = (try? container.decode(String.self, forKey: .bookBackground)) ?? ""
        self.chapterTitles = try container.decode([String].self, forKey: .chapters)
        self.age = (try? container.decode(String.self, forKey: .age)) ?? "Adult"
        self.language = (try? container.decode(String.self, forKey: .language)) ?? "English"
    }
}