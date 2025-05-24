import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var isShowingImport = false
    @State private var syncErrorAlert: SyncAlert? = nil
    @State private var animateContent = false
    
    struct SyncAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerView
                        .padding(.top, 20)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
                    
                    // Hero card with latest stats
                    if !dataStore.allReadings.isEmpty {
                        BPSummaryCard(stats: dataStore.latestStats, readings: dataStore.allReadings)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                    }
                    
                    // Quick actions
                    actionButtonsSection
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
                    
                    // 30-day BP Trend Chart
                    if !dataStore.allReadings.isEmpty {
                        SimpleBPChart(readings: dataStore.allReadings)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
                    }
                    
                    // Recent readings section
                    if !dataStore.recentReadings.isEmpty {
                        recentReadingsSection
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateContent)
                    } else {
                        emptyStateView
                            .padding(.top, 60)
                            .opacity(animateContent ? 1 : 0)
                            .scaleEffect(animateContent ? 1 : 0.9)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
                    }
                }
                .padding(.bottom, 100) // Space for tab bar
            }
            .background(Color.primaryBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $isShowingImport) {
            ImportView()
        }
        .sheet(isPresented: $healthKitManager.showingSyncModal) {
            SyncHealthModalWrapper()
                .environmentObject(dataStore)
                .environmentObject(healthKitManager)
        }
        .alert(item: $syncErrorAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Your health journey continues")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // Profile/Settings button
            IconActionButton(
                icon: "person.circle.fill",
                size: 44,
                color: .primaryAccent
            ) {
                // Navigate to profile/settings
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            ActionButton(
                title: "Import",
                icon: "square.and.arrow.down.fill",
                style: .primary
            ) {
                isShowingImport = true
            }
            .frame(maxWidth: .infinity)
            
            ActionButton(
                title: "Sync",
                icon: "arrow.triangle.2.circlepath",
                style: .secondary,
                isLoading: isSyncInProgress
            ) {
                syncToHealthKit()
            }
            .disabled(!canSync)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
    }
    
    private var recentReadingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recent Readings")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    Text("\(dataStore.recentReadings.count) readings")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                NavigationLink(destination: AllReadingsView()) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
            .padding(.horizontal, 20)
            
            // Readings carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(dataStore.recentReadings.prefix(8)) { reading in
                        ReadingCard(reading: reading)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.primaryAccent.opacity(0.1), Color.primaryAccent.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 50))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.primaryAccent, Color.secondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .symbolEffect(.pulse)
            }
            
            VStack(spacing: 8) {
                Text("No Readings Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text("Import your Hilo report to start tracking\nyour blood pressure journey")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondaryText)
            }
            
            ActionButton(
                title: "Import Your First Report",
                icon: "doc.badge.plus",
                style: .primary
            ) {
                isShowingImport = true
            }
            .frame(maxWidth: 280)
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Computed Properties
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private var isSyncInProgress: Bool {
        switch healthKitManager.syncState {
        case .preparing, .syncing: return true
        default: return false
        }
    }
    
    private var canSync: Bool {
        // Check if we have readings and HealthKit is available
        return !dataStore.allReadings.isEmpty && healthKitManager.canSync
    }
    
    // MARK: - Methods
    
    private func syncToHealthKit() {
        switch healthKitManager.authStatus {
        case .full, .partial:
            healthKitManager.showingSyncModal = true
            
        case .checking, .denied, .unavailable:
            Task {
                let success = await healthKitManager.requestPermissions()
                
                if success {
                    await MainActor.run {
                        healthKitManager.showingSyncModal = true
                    }
                } else {
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

// MARK: - Wrapper View for SyncHealthModal
// This solves the property wrapper hell by creating a clean boundary
struct SyncHealthModalWrapper: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        // Create a computed property to extract the readings
        SyncHealthModal(
            readings: dataStore.allReadings,
            isPresented: $healthKitManager.showingSyncModal
        )
    }
    
}
