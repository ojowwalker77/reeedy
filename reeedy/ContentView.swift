import SwiftUI
import AVFoundation

// Define our custom colors
extension Color {
    static let comfortableWhite = Color(red: 0.98, green: 0.97, blue: 0.93)
}

struct ContentView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var userProfileManager: UserProfileManager
    
    let book: Book
    let chapter: Chapter

    public init(book: Book, chapter: Chapter) {
        self.book = book
        self.chapter = chapter
    }
    
    @State private var words: [RhythmicWord] = []
    @State private var currentWordIndex = 0
    @State private var isReading = false
    @State private var showWordMap = false
    
    @State private var timerProgress: CGFloat = 0.0
    
    @State private var readingTask: Task<Void, Error>?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var chapterAudioPlayer: AVAudioPlayer?
    @State private var audioProgressTimer: Timer? = nil

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .comfortableWhite
    }
    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
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
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                if !words.isEmpty {
                    Text(currentWordText)
                        .font(.system(size: CGFloat(appSettings.fontSize), weight: .regular, design: .rounded))
                        .foregroundColor(foregroundColor)
                        .lineSpacing(CGFloat(appSettings.fontSize) * 0.4)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .id("word_\(currentWordIndex)")
                        .transition(.opacity.animation(.easeInOut(duration: 0.15)))
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 100)
            
            VStack(spacing: 20) {
                Spacer()
                HStack {
                    Button(action: {
                        stopReading()
                        showWordMap = true
                    }) {
                        Image(systemName: "text.quote")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        isReading.toggle()
                        if isReading { startReading() } else { stopReading() }
                    }) {
                        Image(systemName: isReading ? "pause.circle" : "play.circle")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
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
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if appSettings.semanticSplittingEnabled {
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(foregroundColor.opacity(0.5))
                            .frame(width: geometry.size.width * timerProgress, height: 2)
                    }
                    .frame(height: 2)
                    .transition(.opacity)
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showWordMap) {
            TimelineView(isPresented: $showWordMap, currentWordIndex: $currentWordIndex, words: words)
        }
        .onAppear {
            setupChapterContent()
        }
        .onDisappear {
            stopReading()
            saveProgress()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(book.title).font(.headline).foregroundColor(foregroundColor)
                    Text(chapter.title)
                        .font(.caption2).foregroundColor(.gray)
                }.onTapGesture { presentationMode.wrappedValue.dismiss() }
            }
        }
    }

    func setupChapterContent() {
        words = chapter.words
        if let lastReadIndex = chapter.lastReadWordIndex {
            currentWordIndex = lastReadIndex
        }

        // Setup chapter audio player
        let audioFileName = book.title.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ".", with: "")
        if let audioURL = Bundle.main.url(forResource: audioFileName, withExtension: "mp3") {
            do {
                chapterAudioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                chapterAudioPlayer?.prepareToPlay()
            } catch {
                print("Error loading chapter audio: \(error.localizedDescription)")
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

        audioProgressTimer?.invalidate()
        audioProgressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard let player = chapterAudioPlayer, player.isPlaying else { return }

            // Update currentWordIndex based on audio progress
            if let timedWords = chapter.timedWords {
                let newIndex = timedWords.firstIndex { word in
                    player.currentTime >= word.start && player.currentTime < word.end
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

            // Update timerProgress for the current word
            if currentWordIndex < chapter.timedWords?.count ?? 0 {
                let currentTimedWord = chapter.timedWords![currentWordIndex]
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
        withAnimation(.easeInOut(duration: 0.2)) {
            timerProgress = 0.0
        }
        chapterAudioPlayer?.pause()
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
    let books = BookLoader.loadBooks()
    let book = books.first!
    let chapter = BookLoader.loadChapter(for: book, title: book.chapterTitles.first!, semanticSplittingEnabled: false)
    
    NavigationView {
        ContentView(book: book, chapter: chapter)
    }
    .environmentObject(AppSettings())
    .environmentObject(UserProfileManager())
}

