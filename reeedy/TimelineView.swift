import SwiftUI

// MARK: - PreferenceKey for Scroll Offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Main Timeline View
struct TimelineView: View {
    // MARK: - Properties
    @Binding var isPresented: Bool
    @Binding var currentWordIndex: Int
    let words: [RhythmicWord]
    @Environment(\.colorScheme) var colorScheme

    // Local state
    @State private var localCurrentWordIndex: Int
    @State private var isInitialLoad = true
    
    // Haptics
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)

    // UI Constants
    private struct Constants {
        static let itemHeight: CGFloat = 70 // Increased for better spacing and larger text
    }

    private var textColor: Color { colorScheme == .dark ? .white : .black }
    private var backgroundColor: Color { colorScheme == .dark ? Color(white: 0.1) : .white }

    // MARK: - Initializer
    init(isPresented: Binding<Bool>, currentWordIndex: Binding<Int>, words: [RhythmicWord]) {
        self._isPresented = isPresented
        self._currentWordIndex = currentWordIndex
        self.words = words
        self._localCurrentWordIndex = State(initialValue: currentWordIndex.wrappedValue)
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topTrailing) {
            backgroundColor.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerView
                timelineScroller
            }

            closeButton
        }
        .onAppear {
            lightImpact.prepare()
            heavyImpact.prepare()
        }
    }

    // MARK: - Subviews
    private var headerView: some View {
        Text("Timeline")
            .font(.system(.largeTitle, design: .rounded).bold())
            .foregroundColor(textColor)
            .padding(.top, 60)
            .padding(.bottom, 20)
    }

    private var timelineScroller: some View {
        GeometryReader { geometry in
            let halfScreen = geometry.size.height / 2
            
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        Color.clear.frame(height: max(0, halfScreen - Constants.itemHeight / 2))

                        ForEach(words.indices, id: \.self) { index in
                            TimelineWordView(
                                word: words[index].word,
                                isSelected: index == localCurrentWordIndex,
                                itemHeight: Constants.itemHeight
                            )
                            .id(index)
                            .onTapGesture {
                                localCurrentWordIndex = index
                                heavyImpact.impactOccurred()
                            }
                        }
                        
                        Color.clear.frame(height: max(0, halfScreen - Constants.itemHeight / 2))
                    }
                    .background(scrollPositionTracker(for: "ScrollView"))
                }
                .coordinateSpace(name: "ScrollView")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { newOffset in
                    guard !isInitialLoad else { return }
                    let newIndex = Int(round(-newOffset / Constants.itemHeight))
                    let clampedIndex = max(0, min(words.count - 1, newIndex))
                    
                    if localCurrentWordIndex != clampedIndex {
                        localCurrentWordIndex = clampedIndex
                        lightImpact.impactOccurred()
                    }
                }
                .onChange(of: localCurrentWordIndex) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        scrollProxy.scrollTo(localCurrentWordIndex, anchor: .center)
                    }
                }
                .onAppear {
                    scrollProxy.scrollTo(currentWordIndex, anchor: .center)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isInitialLoad = false
                    }
                }
                .mask(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black, .black, .black, .clear]),
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
        }
    }

    private var closeButton: some View {
        Button(action: {
            currentWordIndex = localCurrentWordIndex
            isPresented = false
        }) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
                .background(Circle().fill(backgroundColor.opacity(0.8)).scaleEffect(1.2))
        }
        .padding()
    }
    
    private func scrollPositionTracker(for coordinateSpace: String) -> some View {
        GeometryReader { innerGeo in
            Color.clear.preference(
                key: ScrollOffsetPreferenceKey.self,
                value: innerGeo.frame(in: .named(coordinateSpace)).minY
            )
        }
    }
}

// MARK: - Timeline Word View
struct TimelineWordView: View {
    let word: String
    let isSelected: Bool
    let itemHeight: CGFloat
    
    @Environment(\.colorScheme) var colorScheme
    private var textColor: Color { colorScheme == .dark ? .white : .black }

    var body: some View {
        Text(word)
            .font(.system(size: isSelected ? 28 : 22, weight: isSelected ? .bold : .regular, design: .rounded))
            .foregroundColor(textColor)
            .scaleEffect(isSelected ? 1.0 : 0.9)
            .opacity(isSelected ? 1.0 : 0.6)
            .frame(height: itemHeight)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

// MARK: - Previews
#if DEBUG
struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleWords = "Havia Eru, o Único, que em Arda é chamado de Ilúvatar. E ele criou primeiro os Ainur, os Sagrados, gerados por seu pensamento, e eles lhe faziam companhia antes que tudo o mais fosse criado.".components(separatedBy: " ").map { RhythmicWord(word: $0, speedModifier: 1.0) }
        
        TimelineView(
            isPresented: .constant(true),
            currentWordIndex: .constant(10),
            words: sampleWords
        )
    }
}
#endif