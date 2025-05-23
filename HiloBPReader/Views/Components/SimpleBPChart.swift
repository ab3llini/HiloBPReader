import SwiftUI
import Charts

struct SimpleBPChart: View {
    let readings: [BloodPressureReading]
    
    @State private var chartData: [BPChartPoint] = []
    @State private var dateRange: ClosedRange<Date> = Date()...Date()
    @State private var scrollOffset: CGFloat = 0
    
    private let windowDays = 30
    private let dayWidth: CGFloat = 12
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            chartHeader
            
            Chart(chartData) { point in
                // Systolic points
                if point.type == .systolic {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Systolic", point.value)
                    )
                    .foregroundStyle(.red)
                    .symbolSize(40)
                }
                
                // Diastolic points
                if point.type == .diastolic {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Diastolic", point.value)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(40)
                }
                
                // Reference lines
                RuleMark(y: .value("Normal Systolic", 120))
                    .foregroundStyle(.green.opacity(0.3))
                    .lineStyle(.init(lineWidth: 1, dash: [5]))
                
                RuleMark(y: .value("Normal Diastolic", 80))
                    .foregroundStyle(.green.opacity(0.3))
                    .lineStyle(.init(lineWidth: 1, dash: [5]))
            }
            .chartYScale(domain: 60...180)
            .chartXScale(domain: dateRange)
            .chartYAxis {
                AxisMarks(values: [60, 80, 120, 140, 160, 180])
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.month().day())
                        }
                    }
                }
            }
            .frame(height: 200)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 30 * 24 * 60 * 60) // 30 days in seconds
            .padding()
            .background(Color.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Stats summary
            if !chartData.isEmpty {
                statsView
            }
        }
        .padding(.horizontal)
        .onAppear { updateChartData() }
        .onChange(of: readings) { _, _ in updateChartData() }
    }
    
    private var chartHeader: some View {
        HStack {
            Text("30 Day Trend")
                .font(.headline)
            
            Spacer()
            
            // Legend
            HStack(spacing: 16) {
                Label("Systolic", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                
                Label("Diastolic", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private var statsView: some View {
        let systolicData = chartData.filter { $0.type == .systolic }
        let diastolicData = chartData.filter { $0.type == .diastolic }
        
        let avgSystolic = systolicData.isEmpty ? 0 : Int(systolicData.map(\.value).reduce(0, +) / Double(systolicData.count))
        let avgDiastolic = diastolicData.isEmpty ? 0 : Int(diastolicData.map(\.value).reduce(0, +) / Double(diastolicData.count))
        
        return HStack {
            StatsBadge(title: "Avg Systolic", value: avgSystolic, color: .red)
            StatsBadge(title: "Avg Diastolic", value: avgDiastolic, color: .blue)
            StatsBadge(title: "Readings", value: readings.count, color: .secondary)
        }
    }
    
    private func updateChartData() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -windowDays, to: endDate)!
        
        dateRange = startDate...endDate
        
        // Filter and group readings by day
        let filteredReadings = readings.filter { $0.date >= startDate && $0.date <= endDate }
        
        var dailyData: [Date: (systolic: [Int], diastolic: [Int])] = [:]
        
        for reading in filteredReadings {
            let day = calendar.startOfDay(for: reading.date)
            if dailyData[day] == nil {
                dailyData[day] = (systolic: [], diastolic: [])
            }
            dailyData[day]?.systolic.append(reading.systolic)
            dailyData[day]?.diastolic.append(reading.diastolic)
        }
        
        // Convert to chart points
        var points: [BPChartPoint] = []
        
        for (date, values) in dailyData {
            if !values.systolic.isEmpty {
                let avgSystolic = Double(values.systolic.reduce(0, +)) / Double(values.systolic.count)
                points.append(BPChartPoint(date: date, value: avgSystolic, type: .systolic))
            }
            
            if !values.diastolic.isEmpty {
                let avgDiastolic = Double(values.diastolic.reduce(0, +)) / Double(values.diastolic.count)
                points.append(BPChartPoint(date: date, value: avgDiastolic, type: .diastolic))
            }
        }
        
        chartData = points.sorted { $0.date < $1.date }
    }
}

struct BPChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let type: BPType
    
    enum BPType {
        case systolic, diastolic
    }
}

struct StatsBadge: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
