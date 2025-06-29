import SwiftUI

struct QuickSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.colorScheme) var colorScheme

    @Binding var currentWordIndex: Int
    let words: [RhythmicWord]
    let chapters: [Chapter]
    let backgroundColor: Color
    var onDone: () -> Void
    
    private var currentChapter: Chapter? {
        chapters.last { $0.startWordIndex <= currentWordIndex }
    }

    @State private var isApplyingSemanticSplitting = false

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                dragIndicator
                
                chapterSelector
                    .padding(.top, 10)
                
                settingsControls
                
                Spacer() // Pushes content to the top
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor.ignoresSafeArea())
            .gesture(
                DragGesture(minimumDistance: 50, coordinateSpace: .local).onEnded { value in
                    if value.translation.height > 50 { // Swipe down
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            onDone()
                        }
                    }
                }
            )

            if isApplyingSemanticSplitting {
                VStack {
                    Text("Applying Setting")
                        .font(.headline)
                    Text("Switching read mode...")
                        .font(.subheadline)
                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
                .foregroundColor(.white)
            }
        }
    }
    
    private var chapterSelector: some View {
        VStack {
            Picker("Chapter", selection: $currentWordIndex) {
                ForEach(chapters) { chapter in
                    Text(chapter.title).tag(chapter.startWordIndex)
                }
            }
            .pickerStyle(.menu)
            .tint(colorScheme == .dark ? .white : .black)
            
            HStack {
                Text("\(currentWordIndex) / \(words.count) words")
                Spacer()
                Text("\(Int(progressPercentage * 100))%")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 40)
        }
    }
    
    @Binding var book: Book

    private var settingsControls: some View {
        VStack(spacing: 30) {
            VStack {
                Label("Reading Speed", systemImage: "speedometer")
                    .font(.headline)
                Text("\(Int(settings.wordsPerMinute)) WPM")
                    .font(.title2)
                    .fontWeight(.bold)
                Slider(value: $settings.wordsPerMinute, in: 100...1000, step: 50)
                    .tint(colorScheme == .dark ? .white : .black)
            }

            VStack {
                Label("Font Size", systemImage: "textformat.size")
                    .font(.headline)
                Text("\(Int(settings.fontSize))")
                    .font(.title2)
                    .fontWeight(.bold)
                Slider(value: $settings.fontSize, in: 20...120, step: 5)
                    .tint(colorScheme == .dark ? .white : .black)
            }
            
            VStack {
                Toggle("Haptic Feedback", isOn: $settings.hapticFeedbackEnabled)
                Toggle("Semantic Splitting", isOn: $settings.semanticSplittingEnabled)
                    .onChange(of: settings.semanticSplittingEnabled) {
                        isApplyingSemanticSplitting = true
                        Task {
                            let reloadedBook = BookLoader.loadBooks(semanticSplittingEnabled: settings.semanticSplittingEnabled).first(where: { $0.id == book.id })
                            if let reloadedBook = reloadedBook {
                                self.book = reloadedBook
                            }
                            isApplyingSemanticSplitting = false
                        }
                    }
                Toggle("Draining Cup Timer", isOn: $settings.drainingCupEnabled)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
        .foregroundColor(colorScheme == .dark ? .white : .black)
    }
    
    private var dragIndicator: some View {
        Capsule()
            .fill(Color.secondary)
            .frame(width: 40, height: 5)
            .padding(.top, 10)
    }
    
    private var progressPercentage: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(words.count)
    }
}

#Preview {
    let chapters = [
        Chapter(title: "Chapter 1", words: [RhythmicWord(word: "Once", speedModifier: 1.0), RhythmicWord(word: "upon", speedModifier: 1.0), RhythmicWord(word: "a", speedModifier: 1.0), RhythmicWord(word: "time...", speedModifier: 1.0)], startWordIndex: 0),
        Chapter(title: "Chapter 2", words: [RhythmicWord(word: "The", speedModifier: 1.0), RhythmicWord(word: "story", speedModifier: 1.0), RhythmicWord(word: "continues...", speedModifier: 1.0)], startWordIndex: 100)
    ]
    let words = chapters.flatMap { $0.words }
    let book = Book(title: "Preview Book", author: "Author", imageName: "", chapters: chapters)
    
    ZStack {
        Color.gray.ignoresSafeArea()
        QuickSettingsView(
            currentWordIndex: .constant(150),
            words: words,
            chapters: chapters,
            backgroundColor: .black,
            onDone: {}, book: .constant(book)
        )
        .environmentObject(AppSettings())
    }
}
