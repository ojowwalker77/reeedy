
import Foundation

class UserProfileManager: ObservableObject {
    @Published var userProfile: UserProfile

    private static let profileURL: URL = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("userProfile.json")
    }()

    init() {
        self.userProfile = UserProfileManager.loadProfile()
    }

    static func loadProfile() -> UserProfile {
        if let data = try? Data(contentsOf: profileURL) {
            if var profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                if profile.selectedProfile == nil {
                    profile.selectedProfile = "Adult"
                }
                return profile
            }
        }
        return UserProfile(selectedProfile: "Adult", readingHistory: [])
    }

    func saveProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            try? data.write(to: Self.profileURL, options: [.atomic, .completeFileProtection])
        }
    }

    func selectProfile(_ profile: String) {
        userProfile.selectedProfile = profile
        objectWillChange.send()
        saveProfile()
    }

    func saveReadingProgress(for bookTitle: String, progress: ReadingProgress) {
        if let index = userProfile.readingHistory.firstIndex(where: { $0.bookTitle == bookTitle && $0.chapterTitle == progress.chapterTitle }) {
            userProfile.readingHistory[index] = progress
        } else {
            userProfile.readingHistory.append(progress)
        }
        objectWillChange.send() // Manually notify subscribers of impending change
        saveProfile()
    }

    func readingProgress(for bookTitle: String, chapter chapterTitle: String) -> ReadingProgress? {
        userProfile.readingHistory.first { $0.bookTitle == bookTitle && $0.chapterTitle == chapterTitle }
    }
}
