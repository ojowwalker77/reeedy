import SwiftUI

// Define our custom colors
extension Color {
    static let comfortableWhite = Color(red: 0.98, green: 0.97, blue: 0.93)
}

struct ContentView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appSettings: AppSettings
    
    @State var book: Book
    @State private var words: [RhythmicWord] = []
    @State private var currentWordIndex = 0
    @State private var isReading = true
    @State private var wasReading = false
    @State private var initialSemanticSplittingEnabled: Bool?
    @State private var timerProgress: CGFloat = 0.0
    
    @State private var showSettings = false
    @State private var readingTask: Task<Void, Error>?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .comfortableWhite
    }
    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var drainingCupColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color(red: 1.0, green: 0.98, blue: 0.9)
    }
    
    private var currentChapter: Chapter? {
        book.chapters.last { $0.startWordIndex <= currentWordIndex }
    }

    private var progress: CGFloat {
        guard !words.isEmpty else { return 0 }
        return CGFloat(currentWordIndex) / CGFloat(words.count - 1)
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            if appSettings.semanticSplittingEnabled && appSettings.drainingCupEnabled {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(drainingCupColor)
                        .frame(height: geometry.size.height)
                        .scaleEffect(y: timerProgress, anchor: .bottom)
                }
                .ignoresSafeArea()
            }

            VStack {
                if !words.isEmpty {
                    Text(words[currentWordIndex].word)
                        .font(.system(size: CGFloat(appSettings.fontSize), weight: .regular, design: .rounded)) // Convert to CGFloat here
                        .foregroundColor(foregroundColor)
                        .padding()
                        .id("word_\(currentWordIndex)")
                        .transition(.opacity.animation(.easeInOut(duration: 0.08)))
                }
            }
            .padding(.bottom, 100)
            
            VStack {
                Spacer()
                chapterAndProgressBarView
                swipeUpIndicator
            }

            if showSettings {
                QuickSettingsView(
                    currentWordIndex: $currentWordIndex, 
                    words: words, 
                    chapters: book.chapters,
                    backgroundColor: backgroundColor,
                    onDone: { closeSettings() },
                    book: $book
                )
                .environmentObject(appSettings)
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !showSettings {
                isReading.toggle()
                if isReading { startReading() } else { stopReading() }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local).onEnded { value in
                if showSettings { return }
                
                // Swipe up for settings
                if value.translation.height < -50 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        wasReading = isReading
                        stopReading()
                        isReading = false
                        showSettings = true
                    }
                    return
                }
            }
        )
        .onAppear {
            self.initialSemanticSplittingEnabled = appSettings.semanticSplittingEnabled
            setupBookContent()
            startReading()
        }
        .onDisappear(perform: stopReading)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(book.title).font(.headline).foregroundColor(foregroundColor)
                    if let chapter = currentChapter {
                        Text(chapter.title)
                            .font(.caption2).foregroundColor(.gray)
                    }
                }.onTapGesture { presentationMode.wrappedValue.dismiss() }
            }
        }
    }

    private var chapterAndProgressBarView: some View {
        VStack {
            if let chapter = currentChapter {
                Text(chapter.title)
                    .font(.headline)
                    .foregroundColor(foregroundColor)
                    .padding(.bottom, 5)
            }
            chapterProgressBarView
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    private var chapterProgressBarView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.gray.opacity(0.5)).frame(height: 4)
                Rectangle().fill(foregroundColor).frame(width: progressWidth(geometry.size.width), height: 4)
                ForEach(book.chapters) { chapter in
                    Button(action: { currentWordIndex = chapter.startWordIndex }) {
                        Circle().fill(foregroundColor).frame(width: 10, height: 10)
                    }.position(x: markerPosition(for: chapter.startWordIndex, in: geometry.size.width), y: geometry.size.height / 2)
                }
            }
        }
        .frame(height: 20)
    }

    private func closeSettings() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showSettings = false
            if wasReading {
                startReading()
            }
        }
    }

    func setupBookContent() {
        words = book.chapters.flatMap { $0.words }
    }

    func startReading() {
        stopReading()
        isReading = true

        readingTask = Task {
            while isReading && currentWordIndex < words.count - 1 {
                let currentRhythmicWord = words[currentWordIndex]
                var interval: Double

                if appSettings.semanticSplittingEnabled {
                    let wordCount = Double(currentRhythmicWord.word.split(separator: " ").count)
                    var baseInterval = (60.0 / appSettings.wordsPerMinute) * max(1.0, wordCount)
                    baseInterval /= currentRhythmicWord.speedModifier

                    interval = baseInterval

                    // "Filling the cup" animation
                    if appSettings.drainingCupEnabled {
                        timerProgress = 1.0
                        withAnimation(.linear(duration: interval)) {
                            timerProgress = 0.0
                        }
                    }

                } else { // Single word logic
                    interval = 60.0 / appSettings.wordsPerMinute
                    interval /= currentRhythmicWord.speedModifier
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
            if currentWordIndex >= words.count - 1 {
                isReading = false
            }
        }
    }

    func stopReading() {
        isReading = false
        readingTask?.cancel()
        readingTask = nil
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard words.count > 1 else { return 0 }
        return totalWidth * CGFloat(currentWordIndex) / CGFloat(words.count - 1)
    }

    private func markerPosition(for index: Int, in totalWidth: CGFloat) -> CGFloat {
        guard words.count > 1 else { return 0 }
        return totalWidth * CGFloat(index) / CGFloat(words.count - 1)
    }
    
    private var swipeUpIndicator: some View {
        Image(systemName: "chevron.up")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom, 10)
    }
}

#Preview {
    NavigationView {
        ContentView(book: BookLoader.loadBooks(semanticSplittingEnabled: false).first!)
    }
    .environmentObject(AppSettings())
}
