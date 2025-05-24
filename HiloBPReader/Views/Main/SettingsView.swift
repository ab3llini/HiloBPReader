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
                    
                    // Show info button
                    Button("About Apple Health Integration") {
                        showingHealthKitInfo = true
                    }
                    
                    // Request permissions button (if needed)
                    if needsPermissionRequest {
                        Button(action: {
                            Task {
                                _ = await healthKitManager.requestPermissions()
                            }
                        }) {
                            HStack {
                                Text("Request Health Access")
                                Spacer()
                                if healthKitManager.authStatus == .checking {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        .disabled(healthKitManager.authStatus == .checking)
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
                    // Total readings with icon
                    HStack {
                        Label("Total Readings", systemImage: "waveform.path.ecg")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(dataStore.totalReadingsCount)")
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .rounded))
                    }
                    
                    // Date range with icon
                    HStack {
                        Label("Date Range", systemImage: "calendar")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(dataStore.dateRange)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    // Imported reports count
                    HStack {
                        Label("Reports Imported", systemImage: "doc.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(dataStore.importedReports.count)")
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .rounded))
                    }
                    
                    // Users (if multiple people use the app)
                    if dataStore.uniqueMemberNames.count > 1 {
                        HStack {
                            Label("Users", systemImage: "person.2.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(dataStore.uniqueMemberNames.joined(separator: ", "))
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                } header: {
                    Text("Data Summary")
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://hilo.com")!) {
                        HStack {
                            Text("Hilo Website")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                    }
                    
                    // Import history (shows last few imports)
                    if !dataStore.importedReports.isEmpty {
                        NavigationLink(destination: ImportHistoryView()) {
                            HStack {
                                Text("Import History")
                                Spacer()
                                Text("\(dataStore.importedReports.count)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(10)
                            }
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
                    dataStore.clearAllData()
                }
            } message: {
                Text("This will remove all imported readings from the app. This cannot be undone.")
            }
            .sheet(isPresented: $showingHealthKitInfo) {
                HealthKitInfoView(isPresented: $showingHealthKitInfo)
            }
        }
    }
    
    private var healthStatusBadge: some View {
        Group {
            switch healthKitManager.authStatus {
            case .full:
                Text("Full Access")
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(8)
            case .partial:
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
            case .checking:
                Text("Checking...")
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(8)
            case .unavailable:
                Text("Not Available")
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray)
                    .cornerRadius(8)
            }
        }
    }
    
    private var needsPermissionRequest: Bool {
        switch healthKitManager.authStatus {
        case .denied, .checking:
            return true
        default:
            return false
        }
    }
}

// New view for import history
struct ImportHistoryView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        List {
            ForEach(dataStore.importedReports.sorted(by: { $0.importDate > $1.importDate })) { report in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(report.month) \(report.year)")
                                .font(.headline)
                            Text(report.memberName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(report.readingCount) readings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(report.importDate, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Import History")
        .navigationBarTitleDisplayMode(.inline)
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
                    if healthKitManager.authStatus == .denied || healthKitManager.authStatus == .checking {
                        Button(action: {
                            Task {
                                _ = await healthKitManager.requestPermissions()
                            }
                        }) {
                            HStack {
                                if healthKitManager.authStatus == .checking {
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
                        .disabled(healthKitManager.authStatus == .checking)
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
        Group {
            switch healthKitManager.authStatus {
            case .full:
                Text("Full Access")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            case .partial:
                Text("Partial Access")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            case .denied:
                Text("Denied")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            case .checking:
                Text("Checking...")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            case .unavailable:
                Text("Not Available")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
}
