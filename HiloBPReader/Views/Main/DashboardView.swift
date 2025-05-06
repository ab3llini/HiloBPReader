import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var isShowingImport = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero card with latest stats
                    BPSummaryCard(stats: dataStore.latestStats)
                    
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
                            isLoading: healthKitManager.syncStatus == .syncing
                        ) {
                            syncToHealthKit()
                        }
                        .disabled(dataStore.currentReport == nil)
                    }
                    .padding(.horizontal)
                    
                    // Recent readings section
                    if !dataStore.recentReadings.isEmpty {
                        RecentReadingsSection(readings: dataStore.recentReadings)
                    } else {
                        EmptyStateView(
                            icon: "waveform.path.ecg",
                            title: "No Readings Yet",
                            message: "Import your Hilo report to visualize your blood pressure data"
                        )
                        .padding(.top, 40)
                    }
                    
                    // Mini trend chart
                    if !dataStore.weeklyTrend.isEmpty {
                        MiniTrendChart(data: dataStore.weeklyTrend)
                            .frame(height: 200)
                            .padding()
                            .background(Color.secondaryBackground)
                            .cornerRadius(16)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.mainBackground.ignoresSafeArea())
            .navigationTitle("Blood Pressure")
            .sheet(isPresented: $isShowingImport) {
                ImportView()
            }
        }
    }
    
    private func syncToHealthKit() {
        guard let report = dataStore.currentReport else { return }
        healthKitManager.syncReadingsToHealthKit(report.readings)
    }
}
