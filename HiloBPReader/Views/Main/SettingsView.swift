import SwiftUI
import HealthKit

struct SettingsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var dataStore: DataStore
    @State private var showingClearConfirmation = false
    @State private var showingHealthKitInfo = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Health Access")
                        Spacer()
                        healthStatusBadge
                    }
                    
                    // Detailed permissions
                    if healthKitManager.authorizationStatus != .notAvailable {
                        VStack {
                            permissionRow(
                                title: "Systolic BP",
                                isGranted: healthKitManager.hasSystolicPermission,
                                icon: "waveform.path.ecg"
                            )
                            
                            permissionRow(
                                title: "Diastolic BP",
                                isGranted: healthKitManager.hasDiastolicPermission,
                                icon: "waveform.path.ecg"
                            )
                            
                            permissionRow(
                                title: "Heart Rate",
                                isGranted: healthKitManager.hasHeartRatePermission,
                                icon: "heart.fill"
                            )
                        }
                    }
                    
                    if healthKitManager.authorizationStatus != .fullAccess &&
                       healthKitManager.authorizationStatus != .notAvailable {
                        Button(action: {
                            requestHealthAccess()
                        }) {
                            HStack {
                                if healthKitManager.isRequestingPermission {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Requesting Access...")
                                } else {
                                    Text("Request Health Access")
                                }
                            }
                        }
                        .disabled(healthKitManager.isRequestingPermission)
                    }
                    
                    Button("About Apple Health Integration") {
                        showingHealthKitInfo = true
                    }
                } header: {
                    Text("Apple Health")
                }
                
                Section {
                    NavigationLink(destination: AllReadingsView()) {
                        Label("View All Readings", systemImage: "list.bullet")
                    }
                    
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("Clear All Imported Data", systemImage: "trash")
                    }
                } header: {
                    Text("Data Management")
                }
                
                Section {
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
                } header: {
                    Text("About")
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
            .sheet(isPresented: $showingHealthKitInfo) {
                HealthKitInfoView(isPresented: $showingHealthKitInfo)
            }
        }
    }
    
    @ViewBuilder
    private var healthStatusBadge: some View {
        switch healthKitManager.authorizationStatus {
        case .fullAccess:
            Text("Full Access")
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green)
                .cornerRadius(8)
        case .partialAccess:
            Text("Partial Access")
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange)
                .cornerRadius(8)
        case .denied:
            Text("Denied")
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .cornerRadius(8)
        case .notDetermined:
            Text("Not Determined")
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary)
                .cornerRadius(8)
        case .notAvailable:
            Text("Not Available")
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray)
                .cornerRadius(8)
        case .unknown:
            Text("Checking...")
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(8)
        }
    }
    
    private func permissionRow(title: String, isGranted: Bool, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func requestHealthAccess() {
        healthKitManager.requestAuthorization { _ in
            // The UI will update based on the published properties
        }
    }
}

// Info view to explain HealthKit permissions
struct HealthKitInfoView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header image
                    HStack {
                        Spacer()
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.pink)
                            .padding(.vertical, 20)
                        Spacer()
                    }
                    
                    // Main content
                    Group {
                        Text("Apple Health Integration")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("This app can sync your blood pressure readings to Apple Health, which allows:")
                            .padding(.top, 8)
                        
                        bulletPoint("Centralized storage of all your health data")
                        bulletPoint("Sharing with your healthcare providers")
                        bulletPoint("Visualization alongside other health metrics")
                        bulletPoint("Integration with other health apps")
                        
                        Text("Permission Status")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        HStack {
                            Text("Current Status:")
                            Spacer()
                            statusBadge
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                        
                        Text("If permission is denied, you can enable it in your device's Settings app:")
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("1. Open the Settings app")
                            Text("2. Scroll down and tap 'Health'")
                            Text("3. Tap 'Data Access & Devices'")
                            Text("4. Find this app and tap it")
                            Text("5. Enable the permissions for blood pressure")
                        }
                        .padding(.leading)
                    }
                    
                    // Request button
                    if healthKitManager.authorizationStatus != .fullAccess &&
                       healthKitManager.authorizationStatus != .partialAccess &&
                       healthKitManager.authorizationStatus != .notAvailable &&
                       healthKitManager.authorizationStatus != .denied {
                        Button(action: {
                            requestHealthAccess()
                        }) {
                            HStack {
                                if healthKitManager.isRequestingPermission {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .foregroundColor(.white)
                                    Text("Requesting Access...")
                                        .foregroundColor(.white)
                                } else {
                                    Text("Request Access Now")
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .disabled(healthKitManager.isRequestingPermission)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("Health Integration", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.blue)
            Text(text)
            Spacer()
        }
        .padding(.leading, 8)
    }
    
    private var statusBadge: some View {
        switch healthKitManager.authorizationStatus {
        case .fullAccess:
            return Text("Granted")
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
        case .partialAccess:
            return Text("Partial Access")
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.yellow)
                .foregroundColor(.white)
                .cornerRadius(12)
        case .denied:
            return Text("Denied")
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
        case .notDetermined:
            return Text("Not Determined")
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
        case .notAvailable:
            return Text("Not Available")
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
        case .unknown:
            return Text("Checking...")
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.secondary)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
    
    private func requestHealthAccess() {
        healthKitManager.requestAuthorization()
    }
}


