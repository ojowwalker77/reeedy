import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    
    private var allBooks: [Book] {
        BookLoader.loadBooks(semanticSplittingEnabled: appSettings.semanticSplittingEnabled)
    }
    
    private var featuredBook: Book? {
        allBooks.first { $0.title == "The Silmarillion" }
    }
    
    private var tolkienBooks: [Book] {
        allBooks.filter { $0.author == "J.R.R. Tolkien" && $0.title != "The Silmarillion" }
    }
    
    private var otherBooks: [Book] {
        allBooks.filter { $0.author != "J.R.R. Tolkien" }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let featuredBook = featuredBook {
                        FeaturedCarouselView(book: featuredBook)
                            .frame(height: 500)
                    }

                    if !tolkienBooks.isEmpty {
                        Text("J.R.R. Tolkien")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                        BookListView(books: tolkienBooks)
                    }

                    if !otherBooks.isEmpty {
                        Text("All Books")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                        BookListView(books: otherBooks)
                    }
                }
            }
            .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGray6))
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

struct FeaturedCarouselView: View {
    let book: Book

    var body: some View {
        ZStack(alignment: .center) {
            Image(book.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 500)
                .clipped()
                .overlay(Color.black.opacity(0.4))

            VStack(spacing: 16) {
                Text(book.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                NavigationLink(destination: ContentView(book: book).toolbar(.hidden, for: .tabBar)) {
                    Text("Read Now")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

struct BookListView: View {
    let books: [Book]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(books) { book in
                NavigationLink(destination: ContentView(book: book).toolbar(.hidden, for: .tabBar)) {
                    HStack(spacing: 16) {
                        Image(book.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct FeaturedBookView: View {
    let book: Book

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(book.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 400)
                .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("FEATURED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(book.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Start Reading")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
            )
        }
    }
}



#Preview {
    LibraryView()
        .environmentObject(AppSettings())
}