
import SwiftUI

struct ChapterListView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var userProfileManager: UserProfileManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    let book: Book

    var body: some View {
        ZStack {
            ZStack(alignment: .topLeading) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        BookHeaderView(book: book)
                        ChapterList(book: book)
                    }
                }
                .background(
                    ZStack {
                        Image(book.bookBackground)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .edgesIgnoringSafeArea(.all)

                        // Applying a blur effect to the background
                        if reduceTransparency {
                            Color.black.edgesIgnoringSafeArea(.all)
                        } else {
                            VisualEffectView(effect: UIBlurEffect(style: .dark))
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                )
                .ignoresSafeArea(edges: .top)

                BackButton()
            }
            .navigationBarHidden(true)
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
    }
}

struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    var body: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.backward")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(15)
                .background(Color.black.opacity(differentiateWithoutColor ? 0.8 : 0.4))
                .clipShape(Circle())
        }
        .padding([.top, .leading], 20)
    }
}

struct BookHeaderView: View {
    @EnvironmentObject var appSettings: AppSettings
    let book: Book

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Spacer(minLength: 140)
            
            Image(book.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .cornerRadius(12)
                .shadow(radius: 10)
                .padding(.horizontal)

            Text(book.title)
                .font(appSettings.selectedFont.font(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal)
                .minimumScaleFactor(0.5)
                .lineLimit(nil)

            Text("por \(book.author)")
                .font(appSettings.selectedFont.font(size: 17))
                .foregroundColor(.white.opacity(0.85))
                .minimumScaleFactor(0.5)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }
}

struct ChapterList: View {
    let book: Book
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var userProfileManager: UserProfileManager
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    
    var body: some View {
        let semanticSplittingEnabled = appSettings.semanticSplittingEnabled
        VStack(alignment: .leading, spacing: 12) {
            ForEach(book.chapterTitles.indices, id: \.self) { index in
                let chapterTitle = book.chapterTitles[index]
                let progress = userProfileManager.readingProgress(for: book.title, chapter: chapterTitle)
                let isCompleted = (progress?.lastReadWordIndex ?? 0) >= (progress?.totalWords ?? 1) - 1

                let chapter = BookLoader.loadChapter(for: book, title: chapterTitle, semanticSplittingEnabled: semanticSplittingEnabled, userProfileManager: userProfileManager)
                NavigationLink(value: chapter) {
                    HStack(spacing: 16) {
                        Text("\(index + 1)")
                            .font(appSettings.selectedFont.font(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 35, alignment: .center)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chapterTitle)
                                .font(appSettings.selectedFont.font(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 20)
                    .background(Color.white.opacity(differentiateWithoutColor ? 0.25 : 0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(differentiateWithoutColor ? 0.4 : 0.2), lineWidth: differentiateWithoutColor ? 1.5 : 1)
                    )
                }
            }
        }
        .padding()
    }
}

