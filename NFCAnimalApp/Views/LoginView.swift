import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var errorMessage = ""
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("showWelcome") private var showWelcome = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.cream
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Logo Section
                    VStack(spacing: 15) {
                        Circle()
                            .fill(Theme.darkGreen)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "pawprint.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(Theme.cream)
                            )
                        
                        Text("NFC Animal Passport")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Theme.darkGreen)
                    }
                    
                    // Login Fields Section
                    VStack(spacing: 20) {
                        LoginField(
                            text: $email,
                            placeholder: "Email",
                            systemImage: "envelope.fill",
                            isSecure: false
                        )
                        
                        LoginField(
                            text: $password,
                            placeholder: "Password",
                            systemImage: "lock.fill",
                            isSecure: true
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Login Button
                    Button(action: {
                        signIn()
                    }) {
                        Text("Login")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.rust)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    
                    // Register Button
                    Button(action: {
                        signUp()
                    }) {
                        Text("Register")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.rust)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.rust, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 60)
            }
            .alert(errorMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            showingAlert = true
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingAlert = true
            } else {
                isLoggedIn = true
            }
        }
    }
    
    private func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            showingAlert = true
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingAlert = true
            } else if let user = result?.user {
                // Firestore'a userType: 'pet-owner' olarak kaydet
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "email": email,
                    "userType": "pet-owner"
                ]) { firestoreError in
                    if let firestoreError = firestoreError {
                        errorMessage = "Firestore error: \(firestoreError.localizedDescription)"
                        showingAlert = true
                    } else {
                        // Register sonrası Welcome Page göster
                        showWelcome = true
                        // Automatically sign in after successful registration
                        signIn()
                    }
                }
            }
        }
    }
}

struct LoginField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    let isSecure: Bool
    @State private var showPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(Theme.darkGreen)
                if isSecure {
                    Group {
                        if showPassword {
                            TextField("", text: $text)
                                .foregroundColor(Theme.darkGreen)
                                .placeholder(when: text.isEmpty) {
                                    Text(placeholder)
                                        .foregroundColor(Theme.darkGreen.opacity(0.6))
                                }
                        } else {
                            SecureField("", text: $text)
                                .foregroundColor(Theme.darkGreen)
                                .placeholder(when: text.isEmpty) {
                                    Text(placeholder)
                                        .foregroundColor(Theme.darkGreen.opacity(0.6))
                                }
                        }
                    }
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Theme.darkGreen)
                    }
                } else {
                    TextField("", text: $text)
                        .foregroundColor(Theme.darkGreen)
                        .autocapitalization(.none)
                        .keyboardType(placeholder == "Email" ? .emailAddress : .default)
                        .placeholder(when: text.isEmpty) {
                            Text(placeholder)
                                .foregroundColor(Theme.darkGreen.opacity(0.6))
                        }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.lightGreen, lineWidth: 1)
            )
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 