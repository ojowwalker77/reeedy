import SwiftUI

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @Binding var isOnboarding: Bool
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            LanguageView(selection: $selection)
                .tag(0)
            WelcomeView(selection: $selection)
                .tag(1)
            NameView(selection: $selection)
                .tag(2)
            ThemeView(selection: $selection)
                .tag(3)
            FinishView(isOnboarding: $isOnboarding, selection: $selection)
                .tag(4)
        }
        .tabViewStyle(PageTabViewStyle())
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .preferredColorScheme(.dark)
    }
}

// MARK: - Reusable Container
struct OnboardingStepWrapper<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Spacer()
            content
            Spacer()
            Spacer()
        }
        .padding(30)
    }
}

// MARK: - Onboarding Steps

struct LanguageView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Binding var selection: Int

    var body: some View {
        OnboardingStepWrapper {
            Text("Welcome")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .padding(.bottom, 30)

            VStack(spacing: 15) {
                OnboardingActionButton(title: "English") {
                    appSettings.selectedLanguage = "English"
                    withAnimation { selection = 1 }
                }
                OnboardingActionButton(title: "Português") {
                    appSettings.selectedLanguage = "Portuguese"
                    withAnimation { selection = 1 }
                }
            }
        }
    }
}

struct WelcomeView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Binding var selection: Int

    var body: some View {
        OnboardingStepWrapper {
            Image(systemName: "text.book.closed.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)

            Text(appSettings.selectedLanguage == "Portuguese" ? "Bem-vindo ao Reeedy" : "Welcome to Reeedy")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text(appSettings.selectedLanguage == "Portuguese" ? "A maneira mais inteligente de ler." : "The smartest way to read.")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 5)

            OnboardingActionButton(title: appSettings.selectedLanguage == "Portuguese" ? "Continuar" : "Continue") {
                withAnimation { selection = 2 }
            }
            .padding(.top, 30)
        }
    }
}

struct NameView: View {
    @EnvironmentObject var userProfileManager: UserProfileManager
    @EnvironmentObject var appSettings: AppSettings
    @Binding var selection: Int

    var body: some View {
        OnboardingStepWrapper {
            Text(appSettings.selectedLanguage == "Portuguese" ? "Como devemos te chamar?" : "What should we call you?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            TextField(appSettings.selectedLanguage == "Portuguese" ? "Seu nome" : "Your Name", text: $userProfileManager.userProfile.name)
                .textFieldStyle(OnboardingTextFieldStyle())

            OnboardingActionButton(title: appSettings.selectedLanguage == "Portuguese" ? "Próximo" : "Next") {
                withAnimation { selection = 3 }
            }
            .padding(.top, 20)
        }
    }
}

struct ThemeView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Binding var selection: Int

    var body: some View {
        OnboardingStepWrapper {
            Text(appSettings.selectedLanguage == "Portuguese" ? "Personalize sua experiência" : "Personalize your experience")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            ThemePickerView()
                .padding(.bottom, 20)

            OnboardingActionButton(title: appSettings.selectedLanguage == "Portuguese" ? "Próximo" : "Next") {
                withAnimation { selection = 4 }
            }
        }
    }
}

struct FinishView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Binding var isOnboarding: Bool
    @Binding var selection: Int

    var body: some View {
        OnboardingStepWrapper {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding(.bottom, 20)

            Text(appSettings.selectedLanguage == "Portuguese" ? "Tudo pronto!" : "You're all set!")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text(appSettings.selectedLanguage == "Portuguese" ? "Aproveite a leitura com o Reeedy." : "Enjoy reading with Reeedy.")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 5)

            OnboardingActionButton(title: appSettings.selectedLanguage == "Portuguese" ? "Começar a Ler" : "Start Reading") {
                isOnboarding = false
            }
            .padding(.top, 30)
        }
    }
}

// MARK: - Custom UI Components

struct OnboardingActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
    }
}

struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 18, weight: .regular, design: .rounded))
            .padding()
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(15)
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboarding: .constant(true))
            .environmentObject(UserProfileManager())
            .environmentObject(AppSettings())
            .environmentObject(ThemeManager())
    }
}