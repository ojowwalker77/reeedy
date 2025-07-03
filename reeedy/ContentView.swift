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

    @StateObject private var viewModel: ContentViewModel

    // MARK: - Initializers
    public init(book: Book, chapter: Chapter) {
        _viewModel = StateObject(wrappedValue: ContentViewModel(book: book, chapter: chapter))
    }

    public init(book: Book, chapter: Chapter, navigationPath: Binding<NavigationPath>) {
        _viewModel = StateObject(wrappedValue: ContentViewModel(book: book, chapter: chapter))
    }

    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .comfortableWhite
    }
    private var foregroundColor: Color {
        if viewModel.currentImageName != nil && !reduceTransparency {
            return .white // Always white text over an image
        } else {
            return colorScheme == .dark ? .white : .black
        }
    }

    @ViewBuilder
    private var backgroundContent: some View {
        Group {
            if let imageName = viewModel.currentImageName, !reduceTransparency {
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
        if appSettings.semanticSplittingEnabled, let segments = viewModel.chapter.semanticSegments, !segments.isEmpty {
            return CGFloat(viewModel.currentWordIndex) / CGFloat(segments.count - 1)
        } else if !viewModel.chapter.words.isEmpty {
            return CGFloat(viewModel.currentWordIndex) / CGFloat(viewModel.chapter.words.count - 1)
        }
        return 0
    }
    
    private var currentWordText: String {
        if appSettings.semanticSplittingEnabled, let segments = viewModel.chapter.semanticSegments, viewModel.currentWordIndex < segments.count {
            return segments[viewModel.currentWordIndex].text
        } else if let timedWords = viewModel.chapter.timedWords, viewModel.currentWordIndex < timedWords.count {
            return timedWords[viewModel.currentWordIndex].word
        } else if viewModel.currentWordIndex < viewModel.chapter.words.count {
            return viewModel.chapter.words[viewModel.currentWordIndex].word
        }
        return ""
    }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer()

                if !currentWordText.isEmpty {
                    if appSettings.semanticSplittingEnabled {
                        highlightedSegmentView()
                            .font(appSettings.selectedFont.font(size: CGFloat(appSettings.fontSize)))
                            .lineSpacing(CGFloat(appSettings.fontSize) * 0.4)
                            .minimumScaleFactor(0.5)
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .id("word_\(viewModel.currentWordIndex)")
                            .transition(.opacity.animation(reduceMotion ? .none : .easeInOut(duration: 0.15)))
                    } else {
                        Text(currentWordText)
                            .font(appSettings.selectedFont.font(size: CGFloat(appSettings.fontSize)))
                            .lineSpacing(CGFloat(appSettings.fontSize) * 0.4)
                            .minimumScaleFactor(0.5) // Allow font to shrink
                            .lineLimit(nil) // Allow multiple lines
                            .frame(maxWidth: .infinity, alignment: .center)
                            .id("word_\(viewModel.currentWordIndex)")
                            .transition(.opacity.animation(reduceMotion ? .none : .easeInOut(duration: 0.15)))
                    }
                }
                
                Spacer()
                
                HStack {
                    Button(action: {
                        viewModel.restartChapter()
                    }) {
                        Image(systemName: "gobackward")
                            .font(.title)
                            .foregroundColor(foregroundColor)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.isReading.toggle()
                        if viewModel.isReading { viewModel.startReading() } else { viewModel.stopReading() }
                    }) {
                        Image(systemName: viewModel.isReading ? "pause.circle" : "play.circle")
                            .font(.system(size: 48))
                            .foregroundColor(foregroundColor)
                    }

                    Spacer()

                    Button(action: {
                        if let player = viewModel.chapterAudioPlayer {
                            player.volume = (player.volume > 0) ? 0.0 : 1.0
                        }
                    }) {
                        Image(systemName: (viewModel.chapterAudioPlayer?.volume ?? 1.0) > 0.0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
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
                viewModel.setup(with: appSettings)
            }
            .onDisappear {
                viewModel.stopReading()
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
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(viewModel.book.title)
                        .font(appSettings.selectedFont.font(size: 17, weight: .bold))
                        .foregroundColor(foregroundColor)
                    Text(viewModel.chapter.title)
                        .font(appSettings.selectedFont.font(size: 12))
                        .foregroundColor(.gray)
                }.onTapGesture { dismiss() }
            }
        }
    }

    private func saveProgress() {
        let progress = ReadingProgress(bookTitle: viewModel.book.title, chapterTitle: viewModel.chapter.title, lastReadWordIndex: viewModel.currentWordIndex, totalWords: viewModel.chapter.words.count, date: Date())
        userProfileManager.saveReadingProgress(for: viewModel.book.title, progress: progress)
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard !viewModel.chapter.words.isEmpty else { return 0 }
        return totalWidth * CGFloat(viewModel.currentWordIndex) / CGFloat(viewModel.chapter.words.count - 1)
    }

    private func markerPosition(for index: Int, in totalWidth: CGFloat) -> CGFloat {
        guard !viewModel.chapter.words.isEmpty else { return 0 }
        return totalWidth * CGFloat(index) / CGFloat(viewModel.chapter.words.count - 1)
    }

    private func highlightedSegmentView() -> some View {
        if let player = viewModel.chapterAudioPlayer, let timedWords = viewModel.chapter.timedWords, let segments = viewModel.chapter.semanticSegments {
            let currentTime = player.currentTime
            let currentSegment = segments[viewModel.currentWordIndex]

            let wordsInSegment = timedWords.filter { $0.start >= currentSegment.start && $0.end <= currentSegment.end }

            var attributedString = AttributedString()

            for wordInfo in wordsInSegment {
                var attributes = AttributeContainer()
                if currentTime >= wordInfo.start && currentTime < wordInfo.end {
                    attributes.backgroundColor = .yellow
                    attributes.foregroundColor = .black
                }
                let attributedWord = AttributedString(wordInfo.word, attributes: attributes)
                attributedString.append(attributedWord)
                attributedString.append(AttributedString(" "))
            }

            return Text(attributedString)
        } else {
            return Text(currentWordText)
        }
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


