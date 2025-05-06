import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                NFCTagEditorView()
            }
            .tabItem {
                Image(systemName: "wave.3.right")
                Text("NFC Tag")
            }
            .tag(0)
            
            NavigationView {
                SearchAnimalView()
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Arama")
            }
            .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(Theme.rust)
        .background(Theme.cream.ignoresSafeArea())
        .onAppear {
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            
            // Set the navigation bar appearance
            let navigationAppearance = UINavigationBarAppearance()
            navigationAppearance.configureWithOpaqueBackground()
            navigationAppearance.backgroundColor = .white
            navigationAppearance.shadowColor = .clear
            
            UINavigationBar.appearance().standardAppearance = navigationAppearance
            UINavigationBar.appearance().compactAppearance = navigationAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        }
    }
} 