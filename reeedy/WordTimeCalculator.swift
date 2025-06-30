import Foundation

class WordTimeCalculator {
    static func calculateWordTimes(for words: [RhythmicWord], wpm: Double) -> [WordTiming] {
        return words.map { rhythmicWord in
            let wordCount = Double(rhythmicWord.word.split(separator: " ").count)
            let baseInterval = (60.0 / wpm) * max(1.0, wordCount)
            let interval = baseInterval / rhythmicWord.speedModifier
            return WordTiming(word: rhythmicWord.word, time: interval)
        }
    }
}
