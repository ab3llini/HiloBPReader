import SwiftUI
import Charts

struct ChartsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var showingMorningReadings = true
    @State private var showingEveningReadings = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Time frame selection
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Main BP line chart
                    BloodPressureLineChart(
                        data: dataStore.filteredReadings(for: selectedTimeFrame),
                        showMorning: showingMorningReadings,
                        showEvening: showingEveningReadings
                    )
                    .frame(height: 280)
                    .padding()
                    .background(Color.secondaryBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Filter options
                    HStack {
                        FilterChip(
                            title: "Morning",
                            icon: "sun.and.horizon.fill",
                            isSelected: showingMorningReadings,
                            color: .orange
                        ) {
                            withAnimation {
                                showingMorningReadings.toggle()
                            }
                        }
                        
                        FilterChip(
                            title: "Evening",
                            icon: "moon.stars.fill",
                            isSelected: showingEveningReadings,
                            color: .indigo
                        ) {
                            withAnimation {
                                showingEveningReadings.toggle()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Distribution chart
                    PressureDistributionChart(data: dataStore.allReadings)
                        .frame(height: 200)
                        .padding()
                        .background(Color.secondaryBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    
                    // Daily pattern chart
                    DailyPatternChart(data: dataStore.hourlyAverages)
                        .frame(height: 220)
                        .padding()
                        .background(Color.secondaryBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    
                    // Heart rate chart
                    HeartRateChart(data: dataStore.filteredReadings(for: selectedTimeFrame))
                        .frame(height: 200)
                        .padding()
                        .background(Color.secondaryBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.mainBackground.ignoresSafeArea())
            .navigationTitle("BP Analytics")
        }
    }
}

enum TimeFrame: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
}
