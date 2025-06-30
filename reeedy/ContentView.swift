import SwiftUI

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
    
    @State private var words: [RhythmicWord] = []
    @State private var wordTimings: [WordTiming] = []
    @State private var currentWordIndex = 0
    @State private var isReading = false
    @State private var showWordMap = false
    
    @State private var timerProgress: CGFloat = 0.0
    
    @State private var readingTask: Task<Void, Error>?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

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

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                if !wordTimings.isEmpty {
                    Text(wordTimings[currentWordIndex].word)
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
        wordTimings = WordTimeCalculator.calculateWordTimes(for: words, wpm: appSettings.wordsPerMinute)
        if let lastReadIndex = chapter.lastReadWordIndex {
            currentWordIndex = lastReadIndex
        }
    }

    func startReading() {
        stopReading()
        isReading = true

        readingTask = Task {
            while isReading && currentWordIndex < wordTimings.count - 1 {
                let interval = wordTimings[currentWordIndex].time

                if appSettings.semanticSplittingEnabled {
                    timerProgress = 0.0
                    withAnimation(.linear(duration: interval)) {
                        timerProgress = 1.0
                    }
                }

                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if !isReading { break }

                withAnimation {
                    currentWordIndex += 1
                    if appSettings.hapticFeedbackEnabled {
                        feedbackGenerator.impactOccurred()
                    }
                }
            }
            if currentWordIndex >= wordTimings.count - 1 {
                isReading = false
            }
        }
    }

    func stopReading() {
        isReading = false
        readingTask?.cancel()
        readingTask = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            timerProgress = 0.0
        }
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
    
    return NavigationView {
        ContentView(book: book, chapter: chapter)
    }
    .environmentObject(AppSettings())
    .environmentObject(UserProfileManager())
}
