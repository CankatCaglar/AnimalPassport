import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum UserType: String, CaseIterable {
    case veterinarian = "Veterinarian"
    case owner = "Owner"
    case ministerOfficer = "Minister Officer"
}

struct ProfileView: View {
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage?
    @State private var showingLogoutAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    // User data states
    @State private var username: String = ""
    @State private var userType: UserType = .owner
    @State private var isLoading = true
    @State private var userTypeString: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Profile Photo Section
                    VStack(spacing: 15) {
                        ZStack {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Theme.lightGreen.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60)
                                            .foregroundColor(Theme.darkGreen)
                                    )
                            }
                            
                            Button(action: { showingImagePicker = true }) {
                                Circle()
                                    .fill(Theme.rust)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 15))
                                    )
                            }
                            .offset(x: 45, y: 45)
                        }
                    }
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                    } else {
                        // User Info Section
                        VStack(spacing: 24) {
                            // Username Display
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .foregroundColor(Theme.darkGreen)
                                    .font(.subheadline)
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(Theme.darkGreen)
                                        .frame(width: 20)
                                    Text(username)
                                        .foregroundColor(Theme.darkGreen)
                                    Spacer()
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
                            
                            // User Type Display
                            VStack(alignment: .leading, spacing: 8) {
                                Text("User Type")
                                    .foregroundColor(Theme.darkGreen)
                                    .font(.subheadline)
                                
                                HStack {
                                    Image(systemName: "person.text.rectangle.fill")
                                        .foregroundColor(Theme.darkGreen)
                                        .frame(width: 20)
                                    Text(displayUserType)
                                        .foregroundColor(Theme.darkGreen)
                                    Spacer()
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
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Logout Button
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.rust)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .padding(.top, 50)
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $profileImage)
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                do {
                    try Auth.auth().signOut()
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutUser"), object: nil)
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .onAppear {
            fetchUserData()
        }
    }
    
    private var displayUserType: String {
        switch userTypeString.lowercased() {
        case "veterinarian":
            return "Veterinarian"
        case "pet-owner":
            return "Pet Owner"
        default:
            return "Unknown"
        }
    }
    
    private func fetchUserData() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        
        // Set email as username
        username = user.email ?? "No email found"
        
        // Fetch user type from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            isLoading = false
            
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            if let data = document?.data(), let typeString = data["userType"] as? String {
                userTypeString = typeString
            }
        }
    }
}

struct ProfileTextField: View {
    @Binding var text: String
    let label: String
    let systemImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundColor(Theme.darkGreen)
                .font(.subheadline)
            
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(Theme.darkGreen)
                TextField("", text: $text)
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

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 
