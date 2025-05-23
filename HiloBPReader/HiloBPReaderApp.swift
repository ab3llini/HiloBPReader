import SwiftUI
import HealthKit

@main
struct HiloBPReaderApp: App {
    @StateObject private var dataStore = DataStore()
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(dataStore)
                .environmentObject(healthKitManager)
                .accentColor(Color("AccentColor"))
                // Remove the forced dark mode - let users choose
                .task {
                    // Use the new async method properly
                    _ = await healthKitManager.requestPermissions()
                }
        }
    }
}
