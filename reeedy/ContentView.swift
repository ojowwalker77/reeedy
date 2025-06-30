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
    @State private var wordTimings: [WordTiming] = []
    @State private var currentWordIndex = 0
    @State private var isReading = false
    @State private var showWordMap = false
    
    @State private var timerProgress: CGFloat = 0.0
    
    @State private var readingTask: Task<Void, Error>?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var lofiPlayer: AVAudioPlayer?
    @State private var isLofiPlaying: Bool = false
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
        if appSettings.audioReadingEnabled, let timedWords = chapter.timedWords, currentWordIndex < timedWords.count {
            return timedWords[currentWordIndex].word
        }
        if currentWordIndex < wordTimings.count {
            return wordTimings[currentWordIndex].word
        }
        if currentWordIndex < words.count {
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("word_\(currentWordIndex)")
                        .transition(.opacity.animation(.easeInOut(duration: 0.15)))
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 100)
            
            VStack(spacing: 20) {
                Spacer()
                HStack(spacing: 20) {
                    Button(action: {
                        isReading.toggle()
                        if isReading { startReading() } else { stopReading() }
                    }) {
                        Image(systemName: isReading ? "pause.circle" : "play.circle")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }
                    
                    

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
                        if lofiPlayer?.isPlaying == true {
                            stopLofiMusic()
                        } else {
                            playLofiMusic()
                        }
                    }) {
                        Image(systemName: isLofiPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
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
            setupLofiPlayer()
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
        wordTimings = WordTimeCalculator.calculateWordTimes(for: words, wpm: appSettings.wordsPerMinute)
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

        if appSettings.audioReadingEnabled, let timedWords = chapter.timedWords {
            // Audio Reading Mode: Audio drives word transitions
            guard currentWordIndex < timedWords.count else { return }
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
                    } else if newIndex == nil && currentWordIndex < timedWords.count - 1 && player.currentTime >= timedWords[currentWordIndex].end {
                        // If we are between words and have passed the current word's end, advance to the next
                        currentWordIndex += 1
                    }
                }

                // Update timerProgress for the current word
                if currentWordIndex < chapter.timedWords?.count ?? 0 {
                    let currentTimedWord = chapter.timedWords![currentWordIndex]
                    let progressInWord = (player.currentTime - currentTimedWord.start) / (currentTimedWord.end - currentTimedWord.start)
                    timerProgress = CGFloat(max(0, min(1, progressInWord)))
                }
            } // Missing brace was here

        } else {
            // WPM Reading Mode: WPM drives word transitions
            readingTask = Task {
                while isReading && currentWordIndex < words.count - 1 {
                    var duration: TimeInterval = 0

                    if currentWordIndex < wordTimings.count {
                        duration = wordTimings[currentWordIndex].time
                    } else {
                        duration = 60.0 / appSettings.wordsPerMinute // Fallback
                    }

                    if appSettings.semanticSplittingEnabled {
                        timerProgress = 0.0
                        withAnimation(.linear(duration: duration)) {
                            timerProgress = 1.0
                        }
                    }

                    try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    if !isReading { break }

                    withAnimation {
                        currentWordIndex += 1
                        if appSettings.hapticFeedbackEnabled {
                            feedbackGenerator.impactOccurred()
                        }
                    }
                }
                if currentWordIndex >= words.count - 1 {
                    isReading = false
                }
                chapterAudioPlayer?.stop() // Stop audio when reading finishes
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
        lofiPlayer?.pause()
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

    private func setupLofiPlayer() {
        guard let url = Bundle.main.url(forResource: "lofi_track", withExtension: "mp3") else { return }
        do {
            lofiPlayer = try AVAudioPlayer(contentsOf: url)
            lofiPlayer?.numberOfLoops = -1 // Loop indefinitely
            lofiPlayer?.prepareToPlay()
            lofiPlayer?.currentTime = appSettings.lofiMusicPlaybackTime // Load saved time
        } catch {
            print("Error loading lofi track: \(error.localizedDescription)")
        }
    }

    private func playLofiMusic() {
        lofiPlayer?.play()
        isLofiPlaying = true
    }

    private func stopLofiMusic() {
        lofiPlayer?.pause()
        isLofiPlaying = false
        appSettings.lofiMusicPlaybackTime = lofiPlayer?.currentTime ?? 0.0 // Save current time
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

