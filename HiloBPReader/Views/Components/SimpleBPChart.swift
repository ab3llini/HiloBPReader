import SwiftUI
import Charts

// Main container view
struct SimpleBPChart: View {
    let readings: [BloodPressureReading]
    @State private var processedData: [BPDataPoint] = []
    @State private var dateRange: ClosedRange<Date> = Date()...Date()
    @State private var systolicMean: Double = 0
    @State private var systolicStdDev: Double = 0
    @State private var diastolicMean: Double = 0
    @State private var diastolicStdDev: Double = 0
    
    // New states for scrolling functionality
    @State private var dragOffset: CGFloat = 0
    @State private var accumulatedOffset: CGFloat = 0
    @State private var isScrolling = false
    @State private var rangeStartDate: Date = Date().addingTimeInterval(-30 * 24 * 60 * 60)
    @State private var rangeEndDate: Date = Date()
    @State private var lastDayOffset: Int = 0  // State to track last offset
    @State private var isViewingHistoricalData: Bool = false // New state to track historical view
    @State private var smoothingDisabled = false // Add this to prevent flickering
    
    // For haptic feedback
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack(alignment: .leading) {
            // Title with historical data indicator
            HStack {
                Text("30 Day Trend")
                    .font(.headline)
                
                Spacer()
                
                // Show historical data badge when applicable
                if isViewingHistoricalData {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.orange)
                        Text("Historical Data")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // Chart with gesture
            BPChartView(
                data: processedData,
                dateRange: dateRange
            )
            .animation(smoothingDisabled ? .none : .easeInOut(duration: 0.2), value: dateRange)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        // Disable animation during scrolling to prevent flickering
                        if !smoothingDisabled {
                            smoothingDisabled = true
                        }
                        
                        let newOffset = gesture.translation.width + accumulatedOffset
                        dragOffset = newOffset

                        let dayWidth: CGFloat = 20
                        let dayOffset = Int(newOffset / dayWidth)

                        let calendar = Calendar.current
                        let initialStartDate = calendar.date(byAdding: .day, value: -30, to: Date())!
                        let initialEndDate = Date()

                        // Calculate new dates based on drag offset
                        let newStartDate = calendar.date(byAdding: .day, value: -dayOffset, to: initialStartDate)!
                        let newEndDate = calendar.date(byAdding: .day, value: -dayOffset, to: initialEndDate)!
                        
                        // Prevent scrolling beyond today's date
                        if newEndDate > Date() {
                            // Reset to current date view
                            resetToCurrentDate()
                            return
                        }
                        
                        // Check if we're viewing historical data (more than 1 day in the past)
                        let isHistorical = calendar.date(byAdding: .day, value: -1, to: Date())! > newEndDate
                        isViewingHistoricalData = isHistorical

                        // Only trigger haptic when dayOffset actually changes
                        if dayOffset != lastDayOffset {
                            hapticFeedback.impactOccurred()
                            lastDayOffset = dayOffset
                        }

                        rangeStartDate = newStartDate
                        rangeEndDate = newEndDate
                        dateRange = newStartDate...newEndDate

                        processDataForRange(startDate: newStartDate, endDate: newEndDate)
                    }
                    .onEnded { _ in
                        accumulatedOffset = dragOffset
                        isScrolling = false
                        
                        // Re-enable animations after scrolling
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            smoothingDisabled = false
                        }
                    }
            )
            
            // Date range display - Fixed version of component
            dateRangeDisplay
            
            // Stats info
            StatsInfoView(
                systolicMean: systolicMean,
                systolicStdDev: systolicStdDev,
                diastolicMean: diastolicMean,
                diastolicStdDev: diastolicStdDev,
                isHistorical: isViewingHistoricalData
            )
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .onAppear {
            // Prepare haptic feedback
            hapticFeedback.prepare()
            // Initial data processing
            processData()
        }
        // Add this to make sure the chart refreshes when new readings are imported
        // Updated to use the new onChange syntax for iOS 17+
        .onChange(of: readings.count) { _, _ in
            processData()
        }
        // Also listen for changes to the last reading date which might indicate new data
        .onChange(of: readings.last?.date) { _, _ in
            processData()
        }
    }
    
    private var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: rangeStartDate) + " to " + formatter.string(from: rangeEndDate)
    }
    
    private var dateRangeDisplay: some View {
        HStack {
            Text(formattedDateRange)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Reset button
            if isViewingHistoricalData {
                Button(action: {
                    // Reset to current date
                    resetToCurrentDate()
                    // Provide haptic feedback
                    hapticFeedback.impactOccurred()
                }) {
                    Label("Current", systemImage: "arrow.uturn.left")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(.blue)
            }
        }
        .padding(.horizontal)
    }
    
    // New function to reset to current date
    private func resetToCurrentDate() {
        // Reset the date range to the current date minus 30 days
        let endDate = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        // Update state
        rangeStartDate = startDate
        rangeEndDate = endDate
        dateRange = startDate...endDate
        isViewingHistoricalData = false
        
        // Reset offsets
        dragOffset = 0
        accumulatedOffset = 0
        lastDayOffset = 0
        
        // Process data for current range
        processDataForRange(startDate: startDate, endDate: endDate)
    }
    
    private func processData() {
        // Set date range to last 30 days
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        // Store the initial date range
        rangeStartDate = startDate
        rangeEndDate = endDate
        dateRange = startDate...endDate
        
        // Reset accumulated offset when refreshing
        dragOffset = 0
        accumulatedOffset = 0
        
        // Reset historical flag
        isViewingHistoricalData = false
        
        // Process data for this range
        processDataForRange(startDate: startDate, endDate: endDate)
    }
    
    private func processDataForRange(startDate: Date, endDate: Date) {
        // Filter readings to the given date range
        let filteredReadings = readings.filter {
            reading in reading.date >= startDate && reading.date <= endDate
        }
        
        // Calculate overall stats
        let allSystolicValues = filteredReadings.map { Double($0.systolic) }
        let allDiastolicValues = filteredReadings.map { Double($0.diastolic) }
        
        systolicMean = allSystolicValues.isEmpty ? 0 :
            allSystolicValues.reduce(0, +) / Double(allSystolicValues.count)
        diastolicMean = allDiastolicValues.isEmpty ? 0 :
            allDiastolicValues.reduce(0, +) / Double(allDiastolicValues.count)
        
        systolicStdDev = calculateStandardDeviation(values: allSystolicValues)
        diastolicStdDev = calculateStandardDeviation(values: allDiastolicValues)
        
        // Group by day
        let calendar = Calendar.current
        var dailyReadings: [Date: [BloodPressureReading]] = [:]
        
        for reading in filteredReadings {
            let day = calendar.startOfDay(for: reading.date)
            if dailyReadings[day] == nil {
                dailyReadings[day] = [reading]
            } else {
                dailyReadings[day]?.append(reading)
            }
        }
        
        // Create data points
        var data: [BPDataPoint] = []
        
        for (date, dayReadings) in dailyReadings {
            // Systolic stats
            let systolicValues = dayReadings.map { Double($0.systolic) }
            let systolicMean = systolicValues.reduce(0, +) / Double(systolicValues.count)
            let systolicStdDev = calculateStandardDeviation(values: systolicValues)
            
            // Diastolic stats
            let diastolicValues = dayReadings.map { Double($0.diastolic) }
            let diastolicMean = diastolicValues.reduce(0, +) / Double(diastolicValues.count)
            let diastolicStdDev = calculateStandardDeviation(values: diastolicValues)
            
            data.append(BPDataPoint(
                id: UUID().uuidString + "-sys",
                date: date,
                value: systolicMean,
                type: "Systolic",
                stdDev: systolicStdDev
            ))
            
            data.append(BPDataPoint(
                id: UUID().uuidString + "-dia",
                date: date,
                value: diastolicMean,
                type: "Diastolic",
                stdDev: diastolicStdDev
            ))
        }
        
        // Sort by date
        self.processedData = data.sorted(by: { $0.date < $1.date })
    }
    
    private func calculateStandardDeviation(values: [Double]) -> Double {
        let count = Double(values.count)
        guard count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / count
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / (count - 1)
        return sqrt(variance)
    }
}

// Stats display component
struct StatsInfoView: View {
    let systolicMean: Double
    let systolicStdDev: Double
    let diastolicMean: Double
    let diastolicStdDev: Double
    let isHistorical: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Systolic: \(Int(systolicMean))±\(Int(systolicStdDev))")
                    .font(.caption)
                    .foregroundColor(BPClassificationService.shared.systolicColor(Int(systolicMean)))
                
                Spacer()
                
                Text("Diastolic: \(Int(diastolicMean))±\(Int(diastolicStdDev))")
                    .font(.caption)
                    .foregroundColor(BPClassificationService.shared.diastolicColor(Int(diastolicMean)))
            }
            
            // Display the classification and appropriate message
            if systolicMean > 0 && diastolicMean > 0 {
                let classification = BPClassificationService.shared.classify(
                    systolic: Int(systolicMean),
                    diastolic: Int(diastolicMean)
                )
                
                HStack {
                    Text(classification.rawValue)
                        .font(.caption)
                        .foregroundColor(classification.color)
                    
                    Spacer()
                    
                    // If historical, add a warning
                    if isHistorical {
                        Text("(Historical Data)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

// Simple data structure
struct BPDataPoint: Identifiable {
    let id: String
    let date: Date
    let value: Double
    let type: String
    let stdDev: Double
    
    var color: Color {
        if type == "Systolic" {
            return BPClassificationService.shared.systolicColor(Int(value))
        } else {
            return BPClassificationService.shared.diastolicColor(Int(value))
        }
    }
}
