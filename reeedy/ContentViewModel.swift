import SwiftUI
import AVFoundation

class ContentViewModel: ObservableObject {
    @Published var currentWordIndex = 0
    @Published var isReading = false
    @Published var showWordMap = false
    @Published var currentImageName: String? // New state variable for current image
    @Published var showNextChapterPrompt = false // New state for next chapter prompt
    

    @Published var timerProgress: CGFloat = 0.0

    private var readingTask: Task<Void, Error>?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @Published var chapterAudioPlayer: AVAudioPlayer?
    private var audioProgressTimer: Timer? = nil
    private let audioDelegate = AudioPlayerDelegateHandler()

    let book: Book
    let chapter: Chapter
    var appSettings: AppSettings? // Make appSettings optional

    init(book: Book, chapter: Chapter) {
        self.book = book
        self.chapter = chapter
    }

    func setup(with settings: AppSettings) {
        self.appSettings = settings
        setupChapterContent()
    }

    func setupChapterContent() {
        if let lastReadIndex = chapter.lastReadWordIndex {
            currentWordIndex = lastReadIndex
        }

        // Setup chapter audio player on a background thread
        Task { @MainActor in
            if let booksURL = Bundle.main.url(forResource: "Books", withExtension: nil) {
                let bookDirectory = booksURL.appendingPathComponent(book.title)
                let audioFileName = chapter.title
                let audioURL = bookDirectory.appendingPathComponent("\(audioFileName).mp3")

                do {
                    chapterAudioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                    // Set delegate handler's callbacks
                    audioDelegate.onFinishPlaying = {
                        // self.dismiss()
                    }
                    audioDelegate.onStopReading = {
                        self.stopReading()
                    }
                    chapterAudioPlayer?.delegate = audioDelegate // Set the delegate
                    chapterAudioPlayer?.prepareToPlay()

                    // Pre-load initial image based on current word index
                    if let timedWords = chapter.timedWords, currentWordIndex < timedWords.count,
                       let chapterImages = chapter.chapterImages {
                        let initialTime = timedWords[currentWordIndex].start
                        let initialImage = chapterImages.first {
                            initialTime >= $0.startTime && initialTime < $0.endTime
                        }
                        currentImageName = initialImage?.imageName
                    }

                } catch {
                    print("Error loading chapter audio from \(audioURL.path): \(error.localizedDescription)")
                }
            }
        }
    }

    func startReading() {
        guard let appSettings = appSettings else { return }
        stopReading()
        isReading = true

        if appSettings.semanticSplittingEnabled {
            guard let segments = chapter.semanticSegments, currentWordIndex < segments.count else { return }
            let segment = segments[currentWordIndex]
            chapterAudioPlayer?.currentTime = segment.start
        } else {
            guard let timedWords = chapter.timedWords, currentWordIndex < timedWords.count else { return }
            let word = timedWords[currentWordIndex]
            chapterAudioPlayer?.currentTime = word.start
        }

        chapterAudioPlayer?.play()

        // Set initial image based on current audio time
        if let chapterImages = chapter.chapterImages, let player = chapterAudioPlayer {
            let initialImage = chapterImages.first {
                player.currentTime >= $0.startTime && player.currentTime < $0.endTime
            }
            currentImageName = initialImage?.imageName
        }

        audioProgressTimer?.invalidate()
        audioProgressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard let player = self.chapterAudioPlayer, player.isPlaying else { return }
            guard let appSettings = self.appSettings else { return }

            // Update currentWordIndex based on audio progress
            if appSettings.semanticSplittingEnabled {
                if let segments = self.chapter.semanticSegments {
                    let newIndex = segments.firstIndex {
                        player.currentTime >= $0.start && player.currentTime < $0.end
                    }
                    if let actualNewIndex = newIndex, actualNewIndex != self.currentWordIndex {
                        self.currentWordIndex = actualNewIndex
                        if appSettings.hapticFeedbackEnabled {
                            self.feedbackGenerator.impactOccurred()
                        }
                    } else if newIndex == nil && self.currentWordIndex < segments.count - 1 && player.currentTime >= segments[self.currentWordIndex].end {
                        self.currentWordIndex += 1
                        if appSettings.hapticFeedbackEnabled {
                            self.feedbackGenerator.impactOccurred()
                        }
                    }
                    self.objectWillChange.send()
                }
            } else {
                if let timedWords = self.chapter.timedWords {
                    let newIndex = timedWords.firstIndex {
                        player.currentTime >= $0.start && player.currentTime < $0.end
                    }
                    if let actualNewIndex = newIndex, actualNewIndex != self.currentWordIndex {
                        self.currentWordIndex = actualNewIndex
                        if appSettings.hapticFeedbackEnabled {
                            self.feedbackGenerator.impactOccurred()
                        }
                    } else if newIndex == nil && self.currentWordIndex < timedWords.count - 1 && player.currentTime >= timedWords[self.currentWordIndex].end {
                        // If we are between words and have passed the current word's end, advance to the next
                        self.currentWordIndex += 1
                        if appSettings.hapticFeedbackEnabled {
                            self.feedbackGenerator.impactOccurred()
                        }
                    }
                }
            }

            // Update currentImageName based on audio progress
            if let chapterImages = self.chapter.chapterImages {
                if let currentImage = chapterImages.first(where: { player.currentTime >= $0.startTime && player.currentTime < $0.endTime }) {
                    if currentImage.imageName != self.currentImageName {
                        self.currentImageName = currentImage.imageName
                    }
                }
            }

            // Update timerProgress for the current word
            if let timedWords = self.chapter.timedWords, self.currentWordIndex < timedWords.count {
                let currentTimedWord = timedWords[self.currentWordIndex]
                let progressInWord = (player.currentTime - currentTimedWord.start) / (currentTimedWord.end - currentTimedWord.start)
                self.timerProgress = CGFloat(max(0, min(1, progressInWord)))
            }
        }
    }

    func stopReading() {
        isReading = false
        readingTask?.cancel()
        readingTask = nil
        audioProgressTimer?.invalidate()
        audioProgressTimer = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            timerProgress = 0.0
        }
        chapterAudioPlayer?.pause()
    }

    func restartChapter() {
        stopReading()
        currentWordIndex = 0
        currentImageName = nil // Reset image
        chapterAudioPlayer?.currentTime = 0
    }
}
