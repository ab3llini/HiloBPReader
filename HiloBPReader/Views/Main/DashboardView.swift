import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var isShowingImport = false
    @State private var syncErrorAlert: SyncAlert? = nil
    
    struct SyncAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero card with latest stats
                    BPSummaryCard(stats: dataStore.latestStats, readings: dataStore.allReadings)
                    
                    // Quick actions
                    HStack(spacing: 15) {
                        ActionButton(
                            title: "Import Report",
                            icon: "square.and.arrow.down.fill",
                            backgroundColor: Color.blue.opacity(0.8)
                        ) {
                            isShowingImport = true
                        }
                        
                        ActionButton(
                            title: "Sync Health",
                            icon: "heart.circle.fill",
                            backgroundColor: Color.pink.opacity(0.8),
                            isLoading: isSyncInProgress
                        ) {
                            syncToHealthKit()
                        }
                        .disabled(!canSync)
                    }
                    .padding(.horizontal)
                    
                    // 30-day BP Trend Chart
                    if !dataStore.allReadings.isEmpty {
                        SimpleBPChart(readings: dataStore.allReadings)
                            .padding(.top, 10)
                    }
                    
                    // Recent readings section
                    if !dataStore.recentReadings.isEmpty {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Recent Readings")
                                    .font(.headline)
                                Spacer()
                                NavigationLink(destination: AllReadingsView()) {
                                    Text("View All")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(dataStore.recentReadings.prefix(5)) { reading in
                                        ReadingCard(reading: reading)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        EmptyStateView(
                            icon: "waveform.path.ecg",
                            title: "No Readings Yet",
                            message: "Import your Hilo report to visualize your blood pressure data"
                        )
                        .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.mainBackground.ignoresSafeArea())
            .navigationTitle("Blood Pressure")
        }
        .sheet(isPresented: $isShowingImport) {
            ImportView()
        }
        .sheet(isPresented: $healthKitManager.showingSyncModal) {
            if let report = dataStore.currentReport {
                SyncHealthModal(
                    readings: report.readings,
                    isPresented: $healthKitManager.showingSyncModal
                )
            }
        }
        .alert(item: $syncErrorAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Computed Properties
    private var isSyncInProgress: Bool {
        switch healthKitManager.syncState {
        case .preparing, .syncing: return true
        default: return false
        }
    }
    
    private var canSync: Bool {
        guard let _ = dataStore.currentReport,
              !dataStore.allReadings.isEmpty else { return false }
        
        return healthKitManager.canSync
    }
    
    // MARK: - Methods
    private func syncToHealthKit() {
        guard let report = dataStore.currentReport else { return }
        
        // Handle different authorization states with the new API
        switch healthKitManager.authStatus {
        case .full, .partial:
            // Has permissions - show sync modal
            healthKitManager.showingSyncModal = true
            
        case .checking, .denied, .unavailable:
            // Need to request permissions first
            Task {
                let success = await healthKitManager.requestPermissions()
                
                if success {
                    // Permission granted - show sync modal
                    await MainActor.run {
                        healthKitManager.showingSyncModal = true
                    }
                } else {
                    // Permission failed - show error
                    await MainActor.run {
                        self.syncErrorAlert = SyncAlert(
                            title: "Health Access Required",
                            message: self.getPermissionErrorMessage()
                        )
                    }
                }
            }
        }
    }
    
    private func getPermissionErrorMessage() -> String {
        switch healthKitManager.authStatus {
        case .denied:
            return "Apple Health access has been denied. To enable, go to Settings > Privacy & Security > Health > HiloBPReader and turn on permissions for blood pressure."
        case .unavailable:
            return "Apple Health is not available on this device."
        default:
            return "Blood pressure data cannot be synced without Apple Health permissions."
        }
    }
}
