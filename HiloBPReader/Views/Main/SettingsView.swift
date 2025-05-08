import SwiftUI
import HealthKit

struct SettingsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var dataStore: DataStore
    @State private var showingClearConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Apple Health")) {
                    HStack {
                        Text("Health Access")
                        Spacer()
                        healthStatusText
                    }
                    
                    Button("Request Health Access") {
                        healthKitManager.requestAuthorization()
                    }
                    .disabled(healthKitManager.authorizationStatus == .authorized)
                }
                
                Section(header: Text("Data Management")) {
                    NavigationLink(destination: AllReadingsView()) {
                        Label("View All Readings", systemImage: "list.bullet")
                    }
                    
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("Clear All Imported Data", systemImage: "trash")
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Current Report")
                        Spacer()
                        if let report = dataStore.currentReport {
                            Text("\(report.month) \(report.year) (\(report.readings.count) readings)")
                                .foregroundColor(.secondary)
                        } else {
                            Text("None")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://hilo.com")!) {
                        HStack {
                            Text("Hilo Website")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.mainBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .alert("Clear All Data", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    dataStore.allReadings = []
                    dataStore.currentReport = nil
                }
            } message: {
                Text("This will remove all imported readings from the app. This cannot be undone.")
            }
        }
    }
    
    @ViewBuilder
    private var healthStatusText: some View {
        switch healthKitManager.authorizationStatus {
        case .authorized:
            Text("Granted")
                .foregroundColor(.green)
        case .denied:
            Text("Denied")
                .foregroundColor(.red)
        case .notDetermined:
            Text("Not Determined")
                .foregroundColor(.orange)
        }
    }
}
