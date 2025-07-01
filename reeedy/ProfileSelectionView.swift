import SwiftUI

struct ProfileSelectionView: View {
    @EnvironmentObject var userProfileManager: UserProfileManager
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Use a background image for a richer feel
            Image("Silmarillion")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
                .overlay(Material.ultraThin)
                .blur(radius: 5)

            VStack(spacing: 30) {
                Text("Who's Reading?")
                    .font(.system(size: 40, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    .padding(.top, 50)

                HStack(spacing: 20) {
                    ProfileCardView(
                        profileName: "Adult",
                        image: Image(systemName: "person.fill"),
                        isSelected: userProfileManager.userProfile.selectedProfile == "Adult"
                    )
                    .onTapGesture {
                        userProfileManager.selectProfile("Adult")
                    }

                    ProfileCardView(
                        profileName: "Children",
                        image: Image("KidsProfile"),
                        isSelected: userProfileManager.userProfile.selectedProfile == "Children"
                    )
                    .onTapGesture {
                        userProfileManager.selectProfile("Children")
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    isPresented = false
                }) {
                    Text("Done")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.accentColor, Color.purple]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct ProfileCardView: View {
    let profileName: String
    let image: Image
    var isSelected: Bool

    var body: some View {
        VStack {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding()
                .background(
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                        Circle()
                            .stroke(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                    }
                )
                .clipShape(Circle())
                .foregroundColor(.white)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 5)
                        .shadow(color: isSelected ? Color.accentColor.opacity(0.8) : Color.clear, radius: 10)
                )
                .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)


            Text(profileName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clear)
                .background(.regularMaterial)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

#Preview {
    ProfileSelectionView(isPresented: .constant(true))
        .environmentObject(UserProfileManager())
}
