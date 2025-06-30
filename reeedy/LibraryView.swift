import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    
    @State private var allBooks: [Book] = []
    
    private var featuredBook: Book? {
        allBooks.first { $0.title == "The Silmarillion" }
    }
    
    private var libraryBooks: [Book] {
        allBooks.filter { $0.id != featuredBook?.id }
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if let featuredBook = featuredBook {
                        FeaturedBookView(book: featuredBook)
                            .padding(.bottom, 25)
                    }

                    if !libraryBooks.isEmpty {
                        VStack(alignment: .leading, spacing: 25) {
                            Text("Library")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            BookGridView(books: libraryBooks)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGray6))
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear {
            self.allBooks = BookLoader.loadBooks()
        }
    }
}


struct FeaturedBookView: View {
    let book: Book

    var body: some View {
        NavigationLink(destination: ChapterListView(book: book).toolbar(.hidden, for: .tabBar)) {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text("FEATURED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(6)
                
                Text(book.title)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                Text(book.author)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 350, alignment: .bottomLeading)
            .background {
                Image(book.imageName)
                    .resizable()
                    .scaledToFill()
            }
            .cornerRadius(12)
            .clipped()
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct BookGridView: View {
    let books: [Book]
    
    let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 180))
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 25) {
            ForEach(books) { book in
                NavigationLink(destination: ChapterListView(book: book).toolbar(.hidden, for: .tabBar)) {
                    BookCoverItemView(book: book)
                }
            }
        }
    }
}

struct BookCoverItemView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading) {
            Image(book.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .clipped()
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            Text(book.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(book.author)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    LibraryView()
        .environmentObject(AppSettings())
}
