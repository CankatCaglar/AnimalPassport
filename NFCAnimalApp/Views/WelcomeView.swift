import SwiftUI

struct WelcomeView: View {
    @AppStorage("showWelcome") private var showWelcome = true
    
    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            VStack {
                Spacer()
                Text("Welcome to our app!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Theme.darkGreen)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
                Text("Easily manage and track your animal data\nwith NFC technology.")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.darkGreen)
                    .multilineTextAlignment(.center)
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showWelcome = false }) {
                        HStack(spacing: 6) {
                            Text("Continue")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Theme.rust)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Theme.rust)
                        }
                    }
                    .padding(.trailing, 32)
                    .padding(.bottom, 32)
                }
            }
        }
    }
} 