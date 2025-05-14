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
                Text("Search")
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
            appearance.backgroundColor = UIColor(named: "oliveGreen") ?? UIColor(red: 117/255, green: 121/255, blue: 90/255, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(named: "rust") ?? UIColor(red: 208/255, green: 140/255, blue: 96/255, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(named: "rust") ?? UIColor(red: 208/255, green: 140/255, blue: 96/255, alpha: 1.0)]
            appearance.stackedLayoutAppearance.normal.iconColor = .white
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            
            // Set the navigation bar appearance
            let navigationAppearance = UINavigationBarAppearance()
            navigationAppearance.configureWithOpaqueBackground()
            navigationAppearance.backgroundColor = UIColor(named: "oliveGreen") ?? UIColor(red: 117/255, green: 121/255, blue: 90/255, alpha: 1.0)
            navigationAppearance.shadowColor = .clear
            navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navigationAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            UINavigationBar.appearance().standardAppearance = navigationAppearance
            UINavigationBar.appearance().compactAppearance = navigationAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        }
    }
} 