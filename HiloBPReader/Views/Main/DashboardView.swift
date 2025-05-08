import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var isShowingImport = false
    @State private var isShowingHealthSync = false
    @State private var showingReadingDetails = false
    @State private var selectedReading: BloodPressureReading?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Last reading card
                if let lastReading = dataStore.recentReadings.first {
                    lastReadingCard(reading: lastReading)
                        .transition(.opacity)
                }
                
                // Summary stats
                if !dataStore.allReadings.isEmpty {
                    BPSummaryCard(stats: dataStore.latestStats)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    // Empty state
                    importCard
                }
                
                // Actions
                HStack(spacing: 16) {
                    ActionButton(
                        title: "Import Report",
                        icon: "square.and.arrow.down.fill",
                        backgroundColor: Color.primaryAccent
                    ) {
                        isShowingImport = true
                    }
                    
                    ActionButton(
                        title: "Sync to Health",
                        icon: "heart.circle.fill",
                        backgroundColor: Color.pink,
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
                        .onTapGesture {
                            selectedReading = dataStore.recentReadings.first
                            showingReadingDetails = true
                        }
                }
                
                // Mini trend chart
                if dataStore.weeklyTrend.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Trend")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        MiniTrendChart(data: dataStore.weeklyTrend)
                            .frame(height: 180)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.secondaryBackground)
                            )
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color.mainBackground.ignoresSafeArea())
        .navigationTitle("Dashboard")
        .sheet(isPresented: $isShowingImport) {
            ImportView()
        }
        .sheet(isPresented: $showingReadingDetails) {
            if let reading = selectedReading {
                ReadingDetailView(reading: reading)
            }
        }
        .animation(.spring(), value: dataStore.recentReadings.count)
    }
    
    private var importCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.7))
            
            Text("No readings yet")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Import your Hilo or Aktiia blood pressure report to get started")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button {
                isShowingImport = true
            } label: {
                Text("Import Report")
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.primaryAccent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondaryBackground)
        )
        .padding(.horizontal)
    }
    
    private func lastReadingCard(reading: BloodPressureReading) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest Reading")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(reading.formattedDateTime)
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.7))
                }
                
                Spacer()
                
                if reading.readingType != .normal {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text(readingTypeString(reading.readingType))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
            
            HStack(spacing: 20) {
                // Systolic
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(reading.systolic)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(systolicColor(reading.systolic))
                    Text("SYS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Diastolic
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(reading.diastolic)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(diastolicColor(reading.diastolic))
                    Text("DIA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Heart rate
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red.opacity(0.8))
                        Text("\(reading.heartRate)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                    Text("BPM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // BP Classification
            BPClassificationBadge(
                systolic: reading.systolic,
                diastolic: reading.diastolic
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private func readingTypeString(_ type: BloodPressureReading.ReadingType) -> String {
        switch type {
        case .normal:
            return "Normal"
        case .initialization:
            return "Initialization"
        case .cuffMeasurement:
            return "Cuff"
        case .onDemandPhone:
            return "On Demand"
        }
    }
    
    private func systolicColor(_ value: Int) -> Color {
        if value >= 140 {
            return .red
        } else if value >= 130 {
            return .orange
        } else if value >= 120 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func diastolicColor(_ value: Int) -> Color {
        if value >= 90 {
            return .red
        } else if value >= 80 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func syncToHealthKit() {
        guard let report = dataStore.currentReport else { return }
        healthKitManager.syncReadingsToHealthKit(report.readings)
    }
}
