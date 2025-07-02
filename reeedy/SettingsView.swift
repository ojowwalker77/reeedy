import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(settings.selectedLanguage == "Portuguese" ? "Idioma" : "Language")
                    .font(settings.selectedFont.font(size: 17, weight: .bold))
                    .padding(.top)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)) {
                    LanguagePicker(selectedLanguage: $settings.selectedLanguage)
                }

                Section(header: Text(settings.selectedLanguage == "Portuguese" ? "Geral" : "General")
                    .font(settings.selectedFont.font(size: 17, weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)) {
                    Toggle(isOn: $settings.hapticFeedbackEnabled) {
                        Label(settings.selectedLanguage == "Portuguese" ? "Feedback Tátil" : "Haptic Feedback", systemImage: "iphone.gen3.radiowaves.left.and.right")
                    }
                }
                
                Section(header: Text(settings.selectedLanguage == "Portuguese" ? "Acessibilidade" : "Accessibility")
                    .font(settings.selectedFont.font(size: 17, weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)) {
                    Toggle(isOn: $settings.reduceMotion) {
                        Label(settings.selectedLanguage == "Portuguese" ? "Reduzir Movimento" : "Reduce Motion", systemImage: "hare.fill")
                    }
                    Toggle(isOn: $settings.reduceTransparency) {
                        Label(settings.selectedLanguage == "Portuguese" ? "Reduzir Transparência" : "Reduce Transparency", systemImage: "square.grid.3x3.fill")
                    }
                    FontPickerView()
                    ThemePickerView()
                }
            }
            .navigationTitle(settings.selectedLanguage == "Portuguese" ? "Ajustes" : "Settings")
            .minimumScaleFactor(0.5)
            .lineLimit(1)
        }
        .font(settings.selectedFont.font(size: 17))
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LanguagePicker: View {
    @Binding var selectedLanguage: String
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 15) {
            LanguageButton(language: "Portuguese", flag: "🇧🇷", selectedLanguage: $selectedLanguage)
            LanguageButton(language: "English", flag: "🇺🇸", selectedLanguage: $selectedLanguage)
        }
        .padding(.vertical, 10)
    }
}

struct LanguageButton: View {
    let language: String
    let flag: String
    @Binding var selectedLanguage: String
    @EnvironmentObject var settings: AppSettings

    private var isSelected: Bool {
        selectedLanguage == language
    }

    var body: some View {
        Button(action: { selectedLanguage = language }) {
            HStack {
                Text(flag)
                    .font(.largeTitle)
                Text(language)
                    .font(settings.selectedFont.font(size: 17, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.5), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
        .environmentObject(ThemeManager())
}
