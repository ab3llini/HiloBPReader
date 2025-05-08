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
    
    // For haptic feedback
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack(alignment: .leading) {
            Text("30 Day Trend")
                .font(.headline)
                .padding(.leading)
            
            // Chart with gesture
            BPChartView(
                data: processedData,
                dateRange: dateRange
            )
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let newOffset = gesture.translation.width + accumulatedOffset
                        dragOffset = newOffset
                        
                        // Calculate day offset (20 points per day as an example)
                        let dayWidth: CGFloat = 20
                        let dayOffset = Int(newOffset / dayWidth)
                        
                        // Update date range during drag
                        let calendar = Calendar.current
                        let initialStartDate = calendar.date(byAdding: .day, value: -30, to: Date())!
                        let initialEndDate = Date()
                        
                        // Move the date range based on the drag
                        let newStartDate = calendar.date(byAdding: .day, value: -dayOffset, to: initialStartDate)!
                        let newEndDate = calendar.date(byAdding: .day, value: -dayOffset, to: initialEndDate)!
                        
                        // Only update if date has changed and give haptic feedback
                        if !isScrolling || Int(accumulatedOffset / dayWidth) != Int(newOffset / dayWidth) {
                            hapticFeedback.impactOccurred()
                            isScrolling = true
                        }
                        
                        rangeStartDate = newStartDate
                        rangeEndDate = newEndDate
                        dateRange = newStartDate...newEndDate
                        
                        // Process data for the new range
                        processDataForRange(startDate: newStartDate, endDate: newEndDate)
                    }
                    .onEnded { _ in
                        // Save the accumulated offset
                        accumulatedOffset = dragOffset
                        isScrolling = false
                    }
            )
            
            // Stats info - moved to bottom
            StatsInfoView(
                systolicMean: systolicMean,
                systolicStdDev: systolicStdDev,
                diastolicMean: diastolicMean,
                diastolicStdDev: diastolicStdDev
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
        .onChange(of: readings.count) { _ in
            processData()
        }
        // Also listen for changes to the last reading date which might indicate new data
        .onChange(of: readings.last?.date) { _ in
            processData()
        }
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
    
    var body: some View {
        HStack {
            Text("Systolic: \(Int(systolicMean))±\(Int(systolicStdDev))")
                .font(.caption)
                .foregroundColor(getBPColor(value: systolicMean, isSystolic: true))
            
            Spacer()
            
            Text("Diastolic: \(Int(diastolicMean))±\(Int(diastolicStdDev))")
                .font(.caption)
                .foregroundColor(getBPColor(value: diastolicMean, isSystolic: false))
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
            return getBPColor(value: value, isSystolic: true)
        } else {
            return getBPColor(value: value, isSystolic: false)
        }
    }
}

// Helper function for BP coloring
func getBPColor(value: Double, isSystolic: Bool) -> Color {
    if isSystolic {
        if value < 120 { return .green }
        else if value < 130 { return .yellow }
        else if value < 140 { return .orange }
        else { return .red }
    } else {
        if value < 80 { return .green }
        else if value < 85 { return .yellow }
        else if value < 90 { return .orange }
        else { return .red }
    }
}
