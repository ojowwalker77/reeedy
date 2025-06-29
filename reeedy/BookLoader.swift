
import Foundation

class BookLoader {
    static func loadBooks(semanticSplittingEnabled: Bool) -> [Book] {
        var books: [Book] = []
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)

            for fileURL in fileURLs where fileURL.pathExtension == "json" {
                do {
                    let data = try Data(contentsOf: fileURL)
                    var book = try JSONDecoder().decode(Book.self, from: data)
                    
                    let bookName = fileURL.deletingPathExtension().lastPathComponent
                    let txtURL = bundleURL.appendingPathComponent("\(bookName).txt")
                    
                    if fileManager.fileExists(atPath: txtURL.path) {
                        let fullContent = try String(contentsOf: txtURL, encoding: .utf8)
                        var chapters: [Chapter] = []
                        let lines = fullContent.components(separatedBy: .newlines)
                        
                        var currentChapterTitle: String? = "AINULINDALË"
                        var currentChapterWords: [RhythmicWord] = []
                        var wordCount = 0
                        var nextWordModifier = 1.0

                        for line in lines {
                            if line == line.uppercased() && !line.isEmpty {
                                if let title = currentChapterTitle {
                                    // Don't create an empty chapter if the first line is a title
                                    if !currentChapterWords.isEmpty {
                                        chapters.append(Chapter(title: title, words: currentChapterWords, startWordIndex: wordCount))
                                        wordCount += currentChapterWords.count
                                    }
                                }
                                currentChapterTitle = line
                                currentChapterWords = []
                                nextWordModifier = 1.0
                            } else {
                                if semanticSplittingEnabled {
                                    // Semantic mode: phrases are separated by '~'
                                    let phrases = line.split(separator: "~", omittingEmptySubsequences: true)
                                    for phrase in phrases {
                                        let trimmedPhrase = String(phrase).trimmingCharacters(in: .whitespacesAndNewlines)
                                        let phraseComponents = trimmedPhrase.components(separatedBy: .whitespacesAndNewlines)
                                        
                                        guard let modifierString = phraseComponents.first,
                                              let phraseModifier = Double(modifierString),
                                              phraseComponents.count > 1 else {
                                            if !trimmedPhrase.isEmpty {
                                                currentChapterWords.append(RhythmicWord(word: trimmedPhrase, speedModifier: 1.0))
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
                                            currentChapterWords.append(RhythmicWord(word: combinedText, speedModifier: finalModifier))
                                        }
                                    }
                                } else {
                                    // Default mode: word-by-word, ignoring semantic markers
                                    // First, remove the semantic markers (~x.x) completely using a regular expression
                                    let lineWithoutSemanticMarkers = line.replacingOccurrences(of: "~[0-9.]+", with: "", options: .regularExpression)

                                    let components = lineWithoutSemanticMarkers.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                                    for component in components {
                                        if component.starts(with: "%") {
                                            if let modifier = Double(component.dropFirst()) {
                                                nextWordModifier = modifier
                                            }
                                        } else {
                                            // Just in case any stray '~' characters are left, remove them.
                                            let cleanComponent = component.replacingOccurrences(of: "~", with: "")
                                            if !cleanComponent.isEmpty {
                                                currentChapterWords.append(RhythmicWord(word: cleanComponent, speedModifier: nextWordModifier))
                                                nextWordModifier = 1.0 // Reset after use
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if let title = currentChapterTitle, !currentChapterWords.isEmpty {
                            chapters.append(Chapter(title: title, words: currentChapterWords, startWordIndex: wordCount))
                        }

                        book.chapters = chapters
                    }
                    
                    books.append(book)
                } catch {
                    print("Error processing book from \(fileURL.lastPathComponent): \(error)")
                }
            }
        } catch {
            print("Error reading contents of bundle directory: \(error)")
        }

        return books
    }
}
