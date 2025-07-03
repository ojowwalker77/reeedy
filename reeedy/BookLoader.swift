import Foundation

class BookLoader {
    // Loads the list of books from the "Books" directory in the bundle.
    static func loadBooks() -> [Book] {
        var books: [Book] = []
        let fileManager = FileManager.default

        guard let booksURL = Bundle.main.url(forResource: "Books", withExtension: nil) else {
            print("Error: 'Books' directory not found in the application bundle. Make sure it's added to your Xcode project and the 'Copy Bundle Resources' build phase.")
            return books
        }

        do {
            let bookDirectories = try fileManager.contentsOfDirectory(at: booksURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

            for bookDirectory in bookDirectories where bookDirectory.hasDirectoryPath {
                let bookName = bookDirectory.lastPathComponent
                let jsonURL = bookDirectory.appendingPathComponent("\(bookName).json")

                if fileManager.fileExists(atPath: jsonURL.path) {
                    do {
                        let data = try Data(contentsOf: jsonURL)
                        let book = try JSONDecoder().decode(Book.self, from: data)
                        books.append(book)
                    } catch {
                        print("Error processing book from \(jsonURL.path): \(error)")
                    }
                } else {
                    print("Warning: No JSON file found for book '\(bookName)' at path \(jsonURL.path)")
                }
            }
        } catch {
            print("Error reading contents of 'Books' directory: \(error)")
        }

        return books
    }

    // Loads the content for a single, specific chapter from its text file.
    static func loadChapter(for book: Book, title: String, semanticSplittingEnabled: Bool, userProfileManager: UserProfileManager? = nil) -> Chapter {
        let fileManager = FileManager.default
        
        guard let booksURL = Bundle.main.url(forResource: "Books", withExtension: nil) else {
            print("Error: 'Books' directory not found in the application bundle.")
            return Chapter(title: title, words: [])
        }
        
        let bookDirectory = booksURL.appendingPathComponent(book.title)
        let fileName = "\(title).md"
        let mdURL = bookDirectory.appendingPathComponent(fileName)

        var words: [RhythmicWord] = []

        if fileManager.fileExists(atPath: mdURL.path) {
            do {
                let fullContent = try String(contentsOf: mdURL, encoding: .utf8)
                let lines = fullContent.components(separatedBy: .newlines)

                for line in lines {
                    if semanticSplittingEnabled {
                        words.append(contentsOf: processSemanticLine(line))
                    } else {
                        words.append(contentsOf: processDefaultLine(line))
                    }
                }
            } catch {
                print("Error loading chapter content from \(fileName): \(error)")
            }
        } else {
            print("Chapter file not found: \(mdURL.path)")
        }
        
        var chapter = Chapter(title: title, words: words)
        let audioData = loadAudioData(for: book, chapterTitle: title)
        chapter.timedWords = audioData.timedWords
        chapter.semanticSegments = audioData.semanticSegments
        chapter.chapterImages = loadChapterImages(for: book, chapterTitle: title) // Load chapter images
        if let manager = userProfileManager, let progress = manager.readingProgress(for: book.title, chapter: title) {
            chapter.lastReadWordIndex = progress.lastReadWordIndex
        }
        
        return chapter
    }

    // Processes a line of text in semantic mode.
    private static func processSemanticLine(_ line: String) -> [RhythmicWord] {
        var words: [RhythmicWord] = []
        let phrases = line.split(separator: "~", omittingEmptySubsequences: true)
        for phrase in phrases {
            let trimmedPhrase = String(phrase).trimmingCharacters(in: .whitespacesAndNewlines)
            let phraseComponents = trimmedPhrase.components(separatedBy: .whitespacesAndNewlines)
            
            guard let modifierString = phraseComponents.first,
                  let phraseModifier = Double(modifierString),
                  phraseComponents.count > 1 else {
                if !trimmedPhrase.isEmpty {
                    words.append(RhythmicWord(word: trimmedPhrase, speedModifier: 1.0))
                }
                continue
            }
            
            let wordsAndModifiers = phraseComponents.dropFirst()
            var wordsInPhrase: [String] = []
            var speedModifiersInPhrase: [Double] = []
            var nextWordModifierInPhrase = 1.0
            
            for component in wordsAndModifiers {
                if component.starts(with: "%") {
                    if let mod = Double(component.dropFirst()) {
                        nextWordModifierInPhrase = mod
                    }
                } else {
                    wordsInPhrase.append(component)
                    speedModifiersInPhrase.append(nextWordModifierInPhrase)
                    nextWordModifierInPhrase = 1.0 // Reset after use
                }
            }
            
            if !wordsInPhrase.isEmpty {
                let combinedText = wordsInPhrase.joined(separator: " ")
                let averageModifier = speedModifiersInPhrase.reduce(0, +) / Double(speedModifiersInPhrase.count)
                let finalModifier = phraseModifier * averageModifier
                words.append(RhythmicWord(word: combinedText, speedModifier: finalModifier))
            }
        }
        return words
    }

    // Processes a line of text in default (word-by-word) mode.
    private static func processDefaultLine(_ line: String) -> [RhythmicWord] {
        var words: [RhythmicWord] = []
        var nextWordModifier = 1.0
        let lineWithoutSemanticMarkers = line.replacingOccurrences(of: "~[0-9.]+", with: "", options: .regularExpression)
        let components = lineWithoutSemanticMarkers.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }

        for component in components {
            if component.starts(with: "%") {
                if let modifier = Double(component.dropFirst()) {
                    nextWordModifier = modifier
                }
            } else {
                let cleanComponent = component.replacingOccurrences(of: "~", with: "")
                if !cleanComponent.isEmpty {
                    words.append(RhythmicWord(word: cleanComponent, speedModifier: nextWordModifier))
                    nextWordModifier = 1.0 // Reset after use
                }
            }
        }
        return words
    }

    // Helper struct to decode the Gentle JSON output
    private struct AudioData: Decodable {
        let word_segments: [TimedWord]?
        let segments: [SemanticSegment]?
    }

    // Loads timed word data from a JSON file generated by Gentle.
    static func loadAudioData(for book: Book, chapterTitle: String) -> (timedWords: [TimedWord]?, semanticSegments: [SemanticSegment]?) {
        guard let booksURL = Bundle.main.url(forResource: "Books", withExtension: nil) else {
            print("Error: 'Books' directory not found in the application bundle.")
            return (nil, nil)
        }
        
        let bookDirectory = booksURL.appendingPathComponent(book.title)
        // Assuming the JSON file is named after the chapter with a _whisperx.json suffix
        let jsonFileName = "\(chapterTitle)_whisperx.json"
        let jsonURL = bookDirectory.appendingPathComponent(jsonFileName)

        do {
            let data = try Data(contentsOf: jsonURL)
            let audioData = try JSONDecoder().decode(AudioData.self, from: data)
            return (audioData.word_segments, audioData.segments)
        } catch {
            print("Error loading audio data from \(jsonURL.path): \(error)")
            return (nil, nil)
        }
    }

    // Helper struct to decode the Chapter Images JSON output
    private struct ChapterImageOutput: Decodable {
        let images: [ChapterImage]
    }

    // Loads chapter image data from a JSON file.
    static func loadChapterImages(for book: Book, chapterTitle: String) -> [ChapterImage]? {
        guard let booksURL = Bundle.main.url(forResource: "Books", withExtension: nil) else {
            print("Error: 'Books' directory not found in the application bundle.")
            return nil
        }
        
        let bookDirectory = booksURL.appendingPathComponent(book.title)
        // Assuming the JSON file is named after the chapter with a _images.json suffix
        let jsonFileName = "\(chapterTitle)_images.json"
        let jsonURL = bookDirectory.appendingPathComponent(jsonFileName)

        do {
            let data = try Data(contentsOf: jsonURL)
            let chapterImageOutput = try JSONDecoder().decode(ChapterImageOutput.self, from: data)
            return chapterImageOutput.images
        } catch {
            print("Error loading chapter images from \(jsonURL.path): \(error)")
            return nil
        }
    }
}