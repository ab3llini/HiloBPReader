import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var isShowingImport = false
    
    // Helper to track sync errors
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
                    // Hero card with latest stats - now passing all readings for trend analysis
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
                            isLoading: healthKitManager.syncStatus == .syncing || healthKitManager.syncStatus == .checking
                        ) {
                            syncToHealthKit()
                        }
                        .disabled(dataStore.currentReport == nil ||
                                  healthKitManager.authorizationStatus == .notAvailable ||
                                  healthKitManager.authorizationStatus == .denied ||
                                  (healthKitManager.authorizationStatus != .fullAccess &&
                                   healthKitManager.authorizationStatus != .partialAccess))
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
    
    private func syncToHealthKit() {
        guard let report = dataStore.currentReport else { return }
        
        // Handle different authorization states
        switch healthKitManager.authorizationStatus {
        case .fullAccess, .partialAccess:
            // Has at least some permissions, prepare the sync
            healthKitManager.prepareSync(report.readings)
            
        case .notDetermined, .unknown:
            // Not determined - request permission
            healthKitManager.requestAuthorization { success in
                if success {
                    // If successful, prepare sync
                    self.healthKitManager.prepareSync(report.readings)
                } else {
                    // If failed, show error
                    self.syncErrorAlert = SyncAlert(
                        title: "Health Access Required",
                        message: "Blood pressure data cannot be synced without Apple Health permissions."
                    )
                }
            }
            
        case .denied:
            // Denied - show settings instructions
            syncErrorAlert = SyncAlert(
                title: "Health Access Denied",
                message: "Apple Health access has been denied. To enable, go to Settings > Privacy & Security > Health > HiloBPReader and turn on permissions for blood pressure."
            )
            
        case .notAvailable:
            // Not available
            syncErrorAlert = SyncAlert(
                title: "Health Not Available",
                message: "Apple Health is not available on this device."
            )
        }
    }
}
