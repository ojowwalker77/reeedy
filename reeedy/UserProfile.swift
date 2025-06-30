
import Foundation

struct UserProfile: Codable {
    var readingHistory: [ReadingProgress]
    
    mutating func addReadingProgress(_ progress: ReadingProgress) {
        if let index = readingHistory.firstIndex(where: { $0.bookTitle == progress.bookTitle && $0.chapterTitle == progress.chapterTitle }) {
            readingHistory[index] = progress
        } else {
            readingHistory.append(progress)
        }
    }
}
