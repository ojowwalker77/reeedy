import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct LibraryView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var userProfileManager: UserProfileManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var allBooks: [Book] = []
    
    private var filteredBooks: [Book] {
        allBooks.filter { $0.language == appSettings.selectedLanguage }
    }

    private var featuredBook: Book? {
        filteredBooks.first { $0.title == "Mrs Dalloway" }
    }
    
    private var continueReadingBooks: [Book] {
        let recentBooks = userProfileManager.userProfile.readingHistory
            .sorted { $0.date > $1.date }
            .map { $0.bookTitle }
        
        return filteredBooks.filter { recentBooks.contains($0.title) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    LibraryHeaderView()
                    
                    if let featuredBook = featuredBook {
                        NavigationLink(value: featuredBook) {
                            FeaturedBookView(book: featuredBook)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if !continueReadingBooks.isEmpty {
                        BookCarouselView(title: appSettings.selectedLanguage == "Portuguese" ? "Continue Lendo" : "Continue Reading", books: continueReadingBooks)
                    }
                    
                    BookCarouselView(title: appSettings.selectedLanguage == "Portuguese" ? "Para Crianças" : "For Kids", books: filteredBooks.filter { $0.age == "Children" })
                    
                    BookCarouselView(title: appSettings.selectedLanguage == "Portuguese" ? "Para Adultos" : "For Adults", books: filteredBooks.filter { $0.age == "Adult" })
                }
                .padding(.vertical)
            }
            .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGray6))
            .navigationBarHidden(true)
            .navigationDestination(for: Book.self) { book in
                ChapterListView(book: book)
                    .environmentObject(themeManager)
            }
            .navigationDestination(for: Chapter.self) { chapter in
                if let book = filteredBooks.first(where: { $0.chapterTitles.contains(chapter.title) }) {
                    ContentView(book: book, chapter: chapter)
                        .environmentObject(themeManager)
                }
            }
        }
        .onAppear {
            Task {
                self.allBooks = BookLoader.loadBooks()
            }
        }
    }
}


struct LibraryHeaderView: View {
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(appSettings.selectedLanguage == "Portuguese" ? "Biblioteca" : "Library")
                    .font(appSettings.dyslexiaFontEnabled ? .custom("OpenDyslexic-Bold", size: 34) : .largeTitle)
                    .fontWeight(.bold)
                Text(appSettings.selectedLanguage == "Portuguese" ? "Seus livros em um só lugar" : "Your books in one place")
                    .font(appSettings.dyslexiaFontEnabled ? .custom("OpenDyslexic-Regular", size: 17) : .headline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct BookCarouselView: View {
    let title: String
    let books: [Book]
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(appSettings.dyslexiaFontEnabled ? .custom("OpenDyslexic-Bold", size: 22) : .title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(books) { book in
                        NavigationLink(value: book) {
                            BookCoverItemView(book: book)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FeaturedBookView: View {
    let book: Book
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()
            Text(appSettings.selectedLanguage == "Portuguese" ? "CLÁSSICO" : "CLASSIC")
                .font(appSettings.dyslexiaFontEnabled ? .custom("OpenDyslexic-Bold", size: 13) : .system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.9))
                .cornerRadius(6)
            Text(book.title)
                .font(appSettings.dyslexiaFontEnabled ? .custom("OpenDyslexic-Bold", size: 32) : .system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(radius: 5)
            
            Text((appSettings.selectedLanguage == "Portuguese" ? "por " : "by ") + book.author)
                .font(appSettings.dyslexiaFontEnabled ? .custom("OpenDyslexic-Regular", size: 17) : .system(.headline, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .bottomLeading)
        .background {
            Image(book.imageName)
                .resizable()
                .scaledToFill()
        }
        .cornerRadius(20)
        .padding(.horizontal)
        .clipped()
    }
}

struct BookCoverItemView: View {
    let book: Book
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        VStack(alignment: .leading) {
            Image(book.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 220)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .clipped()
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            Text(book.title)
                .font(appSettings.dyslexiaFontEnabled ? .custom("OpenDyslexic-Bold", size: 17) : .headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(width: 150, alignment: .leading)
            
            Text(book.author)
                .font(appSettings.dyslexiaFontEnabled ? .custom("OpenDyslexic-Regular", size: 15) : .subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(AppSettings())
        .environmentObject(UserProfileManager())
}

#Preview {
    FeaturedBookView(book: BookLoader.loadBooks().first!)
        .environmentObject(AppSettings())
}
