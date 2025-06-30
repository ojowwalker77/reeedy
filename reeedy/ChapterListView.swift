
import SwiftUI

struct ChapterListView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    
    let book: Book

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    BookHeaderView(book: book)
                    ChapterList(book: book, appSettings: appSettings)
                }
            }
            .background(colorScheme == .dark ? .black : Color(UIColor.systemGray6))
            .ignoresSafeArea(edges: .top)

            BackButton()
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.backward")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(12)
                .background(Color.gray.opacity(0.3))
                .clipShape(Circle())
        }
        .padding([.top, .leading])
    }
}

struct BookHeaderView: View {
    let book: Book

    var body: some View {
        VStack(spacing: 15) {
            Spacer(minLength: 60)
            Image(book.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250, height: 250)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
            
            VStack(spacing: 4) {
                Text(book.title)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                
                Text(book.author)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ChapterList: View {
    let book: Book
    let appSettings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(book.chapterTitles.indices, id: \.self) { index in
                NavigationLink(destination: chapterDestination(book.chapterTitles[index])) {
                    HStack(spacing: 15) {
                        Text("\(index + 1)")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .center)
                        
                        Text(book.chapterTitles[index])
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
    }

    private func chapterDestination(_ chapterTitle: String) -> some View {
        let chapter = BookLoader.loadChapter(for: book, title: chapterTitle, semanticSplittingEnabled: appSettings.semanticSplittingEnabled)
        return ContentView(book: book, chapter: chapter)
    }
}

#if DEBUG
struct ChapterListView_Previews: PreviewProvider {
    static var previews: some View {
        let decoder = JSONDecoder()
        let json = """
        {
          "title": "The Silmarillion",
          "author": "J.R.R. Tolkien",
          "imageName": "Silmarillion",
          "Chapters": ["AINULINDALË", "VALAQUENTA", "OF THE BEGINNING OF DAYS", "OF AULË AND YAVANNA"]
        }
        """.data(using: .utf8)!
        let book = try! decoder.decode(Book.self, from: json)

        return NavigationView {
            ChapterListView(book: book)
        }.environmentObject(AppSettings())
    }
}
#endif
