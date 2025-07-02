import Foundation

class WordTimeCalculator {
    static func calculateWordTimes(for words: [RhythmicWord]) -> [WordTiming] {
        let defaultWPM = 200.0 // Using a default WPM since it's no longer user-adjustable
        return words.map { rhythmicWord in
            let wordCount = Double(rhythmicWord.word.split(separator: " ").count)
            let baseInterval = (60.0 / defaultWPM) * max(1.0, wordCount)
            let interval = baseInterval / rhythmicWord.speedModifier
            return WordTiming(word: rhythmicWord.word, time: interval)
        }
    }
}
