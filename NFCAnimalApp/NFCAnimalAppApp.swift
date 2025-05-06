//
//  NFCAnimalAppApp.swift
//  NFCAnimalApp
//
//  Created by BERKE on 9.04.2025.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct NFCAnimalAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("showWelcome") private var showWelcome = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showWelcome {
                    WelcomeView()
                } else if isLoggedIn {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .onAppear {
                // Listen for logout notifications
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("LogoutUser"),
                    object: nil,
                    queue: .main) { _ in
                        isLoggedIn = false
                    }
            }
            .onChange(of: isLoggedIn) { newValue in
                if newValue {
                    // User just logged in
                    print("User logged in successfully")
                } else {
                    // User logged out
                    print("User logged out")
                }
            }
        }
    }
}
