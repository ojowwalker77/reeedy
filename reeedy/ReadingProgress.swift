
import Foundation

struct ReadingProgress: Codable {
    let bookTitle: String
    let chapterTitle: String
    let lastReadWordIndex: Int
    let totalWords: Int
    let date: Date
}
