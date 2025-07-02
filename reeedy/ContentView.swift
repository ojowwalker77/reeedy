import SwiftUI
import AVFoundation

// Define our custom colors
extension Color {
    static let comfortableWhite = Color(red: 0.98, green: 0.97, blue: 0.93)
}



// New class for handling AVAudioPlayerDelegate
class AudioPlayerDelegateHandler: NSObject, AVAudioPlayerDelegate {
    var onFinishPlaying: (() -> Void)?
    var onStopReading: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            onStopReading?()
            onFinishPlaying?()
        }
    }
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var userProfileManager: UserProfileManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss // Use dismiss for popping views
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    let book: Book
    let chapter: Chapter

    // MARK: - Initializers
    /// Designated initializer used throughout the app
    public init(book: Book, chapter: Chapter) {
        self.book = book
        self.chapter = chapter
    }
    
    /// Convenience initializer kept for backward‑compatibility with older call‑sites
    /// that still pass an explicit `navigationPath`. The parameter is ignored because
    /// `ContentView` now receives the path through the environment.
    public init(book: Book, chapter: Chapter, navigationPath: Binding<NavigationPath>) {
        self.book = book
        self.chapter = chapter
        _ = navigationPath // silence “unused” warning
    }

    
    @State private var words: [RhythmicWord] = []
    @State private var currentWordIndex = 0
    @State private var isReading = false
    @State private var showWordMap = false
    @State private var currentImageName: String? // New state variable for current image
    @State private var showNextChapterPrompt = false // New state for next chapter prompt
    
    @State private var timerProgress: CGFloat = 0.0
    
    @State private var readingTask: Task<Void, Error>?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var chapterAudioPlayer: AVAudioPlayer?
    @State private var audioProgressTimer: Timer? = nil
    private let audioDelegate = AudioPlayerDelegateHandler()

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .comfortableWhite
    }
    private var foregroundColor: Color {
        if currentImageName != nil && !reduceTransparency {
            return .white // Always white text over an image
        } else {
            return colorScheme == .dark ? .white : .black
        }
    }

    @ViewBuilder
    private var backgroundContent: some View {
        Group {
            if let imageName = currentImageName, !reduceTransparency {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .overlay(Color.black.opacity(0.4))
                    .transition(.opacity.animation(reduceMotion ? .none : .easeInOut(duration: 1.5)))
            } else {
                backgroundColor
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    private var progress: CGFloat {
        guard !words.isEmpty else { return 0 }
        return CGFloat(currentWordIndex) / CGFloat(words.count - 1)
    }
    
    private var currentWordText: String {
        if let timedWords = chapter.timedWords, currentWordIndex < timedWords.count {
            return timedWords[currentWordIndex].word
        } else if currentWordIndex < words.count {
            return words[currentWordIndex].word
        }
        return ""
    }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer()

                if !words.isEmpty {
                    Text(currentWordText)
                        .font(appSettings.selectedFont.font(size: CGFloat(appSettings.fontSize)))
                        .lineSpacing(CGFloat(appSettings.fontSize) * 0.4)
                        .minimumScaleFactor(0.5) // Allow font to shrink
                        .lineLimit(nil) // Allow multiple lines
                        .frame(maxWidth: .infinity, alignment: .center)
                        .id("word_\(currentWordIndex)")
                        .transition(.opacity.animation(reduceMotion ? .none : .easeInOut(duration: 0.15)))
                }
                
                Spacer()
                
                HStack {
                    Button(action: {
                        restartChapter()
                    }) {
                        Image(systemName: "gobackward")
                            .font(.title)
                            .foregroundColor(foregroundColor)
                    }

                    Spacer()

                    Button(action: {
                        isReading.toggle()
                        if isReading { startReading() } else { stopReading() }
                    }) {
                        Image(systemName: isReading ? "pause.circle" : "play.circle")
                            .font(.system(size: 48))
                            .foregroundColor(foregroundColor)
                    }

                    Spacer()

                    Button(action: {
                        if chapterAudioPlayer?.volume == 0.0 {
                            chapterAudioPlayer?.volume = 1.0 // Unmute
                        } else {
                            chapterAudioPlayer?.volume = 0.0 // Mute
                        }
                    }) {
                        Image(systemName: (chapterAudioPlayer?.volume ?? 1.0) > 0.0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title)
                            .foregroundColor(foregroundColor)
                    }
                }
                
                
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(foregroundColor)
            .background(backgroundContent)
            .preferredColorScheme(colorScheme == .dark ? .dark : .light)
            .onAppear {
                setupChapterContent()
            }
            .onDisappear {
                stopReading()
                saveProgress()
            }
            .navigationBarBackButtonHidden(true)
            
            // Apply the selected themes as an overlay
            ForEach(themeManager.activeOverlays) { theme in
                Rectangle()
                    .fill(theme.overlayColor)
                    .blendMode(theme.blendMode)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    let currentFontIndex = AppFont.allCases.firstIndex(of: appSettings.selectedFont) ?? 0
                    let nextFontIndex = (currentFontIndex + 1) % AppFont.allCases.count
                    appSettings.selectedFont = AppFont.allCases[nextFontIndex]
                }) {
                    Image(systemName: "textformat")
                        .font(.title2)
                        .foregroundColor(foregroundColor)
                }
            }
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(book.title)
                        .font(appSettings.selectedFont.font(size: 17, weight: .bold))
                        .foregroundColor(foregroundColor)
                    Text(chapter.title)
                        .font(appSettings.selectedFont.font(size: 12))
                        .foregroundColor(.gray)
                }.onTapGesture { dismiss() }
            }
        }
    }

    func setupChapterContent() {
        words = chapter.words
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
                        self.dismiss()
                    }
                    audioDelegate.onStopReading = {
                        stopReading()
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
        stopReading()
        isReading = true

        // Audio Reading Mode: Audio drives word transitions
        guard let timedWords = chapter.timedWords, currentWordIndex < timedWords.count else { return }
        let word = timedWords[currentWordIndex]

        chapterAudioPlayer?.currentTime = word.start
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
            guard let player = chapterAudioPlayer, player.isPlaying else { return }

            // Update currentWordIndex based on audio progress
            if let timedWords = chapter.timedWords {
                let newIndex = timedWords.firstIndex {
                    player.currentTime >= $0.start && player.currentTime < $0.end
                }
                if let actualNewIndex = newIndex, actualNewIndex != currentWordIndex {
                    currentWordIndex = actualNewIndex
                    if appSettings.hapticFeedbackEnabled {
                        feedbackGenerator.impactOccurred()
                    }
                } else if newIndex == nil && currentWordIndex < timedWords.count - 1 && player.currentTime >= timedWords[currentWordIndex].end {
                    // If we are between words and have passed the current word's end, advance to the next
                    currentWordIndex += 1
                    if appSettings.hapticFeedbackEnabled {
                        feedbackGenerator.impactOccurred()
                    }
                }
            }

            // Update currentImageName based on audio progress
            if let chapterImages = chapter.chapterImages {
                if let currentImage = chapterImages.first(where: { player.currentTime >= $0.startTime && player.currentTime < $0.endTime }) {
                    if currentImage.imageName != currentImageName {
                        currentImageName = currentImage.imageName
                    }
                }
            }

            // Update timerProgress for the current word
            if let timedWords = chapter.timedWords, currentWordIndex < timedWords.count {
                let currentTimedWord = timedWords[currentWordIndex]
                let progressInWord = (player.currentTime - currentTimedWord.start) / (currentTimedWord.end - currentTimedWord.start)
                timerProgress = CGFloat(max(0, min(1, progressInWord)))
            }
        }
    }

    func stopReading() {
        isReading = false
        readingTask?.cancel()
        readingTask = nil
        audioProgressTimer?.invalidate()
        audioProgressTimer = nil
        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.2)) {
            timerProgress = 0.0
        }
        chapterAudioPlayer?.pause()
    }
    
    func restartChapter() {
        stopReading()
        currentWordIndex = 0
        currentImageName = nil // Reset image
        chapterAudioPlayer?.currentTime = 0
        startReading()
    }
    
    private func saveProgress() {
        let progress = ReadingProgress(bookTitle: book.title, chapterTitle: chapter.title, lastReadWordIndex: currentWordIndex, totalWords: words.count, date: Date())
        userProfileManager.saveReadingProgress(for: book.title, progress: progress)
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard words.count > 1 else { return 0 }
        return totalWidth * CGFloat(currentWordIndex) / CGFloat(words.count - 1)
    }

    private func markerPosition(for index: Int, in totalWidth: CGFloat) -> CGFloat {
        guard words.count > 1 else { return 0 }
        return totalWidth * CGFloat(index) / CGFloat(words.count - 1)
    }
}

#Preview {
    struct ContentViewPreview: View {
        @State private var path = NavigationPath()
        private static var userProfileManager = UserProfileManager()
        private static var book: Book? = BookLoader.loadBooks().first
        
        var body: some View {
            if let book = Self.book {
                let chapter = BookLoader.loadChapter(for: book, title: book.chapterTitles.first!, semanticSplittingEnabled: false, userProfileManager: Self.userProfileManager)
                NavigationStack(path: $path) {
                    ContentView(book: book, chapter: chapter)
                        .navigationDestination(for: Chapter.self) { nextChapter in
                            ContentView(book: book, chapter: nextChapter)
                        }
                }
                .environmentObject(AppSettings())
                .environmentObject(Self.userProfileManager)
                .environmentObject(ThemeManager())
            } else {
                Text("Failed to load book or chapter for preview.")
            }
        }
    }
    
    return ContentViewPreview()
}


