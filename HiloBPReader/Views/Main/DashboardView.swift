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
