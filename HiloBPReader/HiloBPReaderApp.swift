import SwiftUI
import HealthKit

@main
struct HiloBPReaderApp: App {
    @StateObject private var dataStore = DataStore()
    @StateObject private var healthKitManager = HealthKitManager()
    
    init() {
        // Configure global appearance
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(dataStore)
                .environmentObject(healthKitManager)
                .preferredColorScheme(.dark) // Force dark mode for our design
                .tint(Color.primaryAccent) // Global tint color
                .task {
                    _ = await healthKitManager.requestPermissions()
                }
        }
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = UIColor(Color.primaryBackground.opacity(0.9))
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.primaryText),
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.primaryText),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.primaryAccent)
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.secondaryBackground.opacity(0.9))
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(Color.primaryAccent)
        
        // Configure table view appearance
        UITableView.appearance().backgroundColor = UIColor(Color.primaryBackground)
        UITableView.appearance().separatorColor = UIColor(Color.glassBorder)
        
        // Configure scroll view appearance
        UIScrollView.appearance().indicatorStyle = .white
    }
}
