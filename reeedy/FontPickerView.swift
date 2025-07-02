import SwiftUI

struct FontPickerView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack {
            ForEach(AppFont.allCases) { font in
                FontRow(font: font)
            }
        }
    }
}

struct FontRow: View {
    @EnvironmentObject var settings: AppSettings
    let font: AppFont

    private var isSelected: Bool {
        settings.selectedFont == font
    }

    var body: some View {
        Button(action: { settings.selectedFont = font }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(font.rawValue)
                        .font(font.font(size: 17, weight: .semibold))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    let tag = font.tag(for: settings.selectedLanguage)
                    Text(tag.text)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(tag.color)
                        .padding(.top, 2)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
