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
                .preferredColorScheme(.dark)
                .accentColor(Color("AccentColor"))
                .onAppear {
                    healthKitManager.requestAuthorization()
                }
        }
    }
}
