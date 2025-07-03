import SwiftUI

struct WordView: View {
    let word: String
    let isHighlighted: Bool

    var body: some View {
        Text(word)
            .padding(4)
            .background(isHighlighted ? Color.yellow : Color.clear)
            .cornerRadius(5)
    }
}
