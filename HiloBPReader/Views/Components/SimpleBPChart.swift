import SwiftUI
import Charts

struct SimpleBPChart: View {
    let readings: [BloodPressureReading]
    
    @State private var chartData: [BPChartPoint] = []
    @State private var dateRange: ClosedRange<Date> = Date()...Date()
    @State private var selectedPoint: BPChartPoint?
    @State private var showingTooltip = false
    @State private var chartAnimationProgress: CGFloat = 0
    
    private let windowDays = 30
    
    var body: some View {
        VStack(spacing: 16) {
            // Chart header
            chartHeader
            
            // Main chart
            chartView
                .frame(height: 240)
                .padding(.horizontal, 8)
            
            // Legend
            legendView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.glassBorder, lineWidth: 1)
                )
        )
        .cardShadow()
        .padding(.horizontal, 20)
        .onAppear {
            updateChartData()
            withAnimation(.easeOut(duration: 1)) {
                chartAnimationProgress = 1
            }
        }
        .onChange(of: readings) { _, _ in updateChartData() }
    }
    
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("30 Day Trend")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Text("Tap points for details")
                    .font(.caption)
                    .foregroundColor(.tertiaryText)
            }
            
            Spacer()
            
            // View mode toggle could go here
        }
    }
    
    private var chartView: some View {
        Chart {
            // Background reference zones
            RectangleMark(
                yStart: .value("Start", 0),
                yEnd: .value("End", 120)
            )
            .foregroundStyle(Color.bpNormal.opacity(0.05))
            
            RectangleMark(
                yStart: .value("Start", 120),
                yEnd: .value("End", 130)
            )
            .foregroundStyle(Color.bpElevated.opacity(0.05))
            
            RectangleMark(
                yStart: .value("Start", 130),
                yEnd: .value("End", 140)
            )
            .foregroundStyle(Color.bpStage1.opacity(0.05))
            
            RectangleMark(
                yStart: .value("Start", 140),
                yEnd: .value("End", 180)
            )
            .foregroundStyle(Color.bpStage2.opacity(0.05))
            
            // Reference lines
            RuleMark(y: .value("Normal", 120))
                .foregroundStyle(Color.bpNormal.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .leading) {
                    Text("Normal")
                        .font(.caption2)
                        .foregroundColor(.bpNormal)
                        .padding(.horizontal, 4)
                        .background(Color.primaryBackground.opacity(0.8))
                        .cornerRadius(4)
                }
            
            RuleMark(y: .value("Normal", 80))
                .foregroundStyle(Color.bpNormal.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            
            // Data points with animation
            ForEach(chartData) { point in
                if point.type == .systolic {
                    // Line connecting systolic points
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value * Double(chartAnimationProgress))
                    )
                    .foregroundStyle(LinearGradient.systolicGradient)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    .opacity(0.3)
                    
                    // Systolic points
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value * Double(chartAnimationProgress))
                    )
                    .foregroundStyle(LinearGradient.systolicGradient)
                    .symbolSize(selectedPoint?.id == point.id ? 120 : 60)
                    .annotation(position: .top) {
                        if selectedPoint?.id == point.id {
                            tooltipView(for: point)
                        }
                    }
                }
                
                if point.type == .diastolic {
                    // Line connecting diastolic points
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value * Double(chartAnimationProgress))
                    )
                    .foregroundStyle(LinearGradient.diastolicGradient)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    .opacity(0.3)
                    
                    // Diastolic points
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value * Double(chartAnimationProgress))
                    )
                    .foregroundStyle(LinearGradient.diastolicGradient)
                    .symbolSize(selectedPoint?.id == point.id ? 120 : 60)
                }
            }
        }
        .chartYScale(domain: 60...180)
        .chartXScale(domain: dateRange)
        .chartYAxis {
            AxisMarks(values: [60, 80, 100, 120, 140, 160, 180]) { value in
                AxisGridLine()
                    .foregroundStyle(Color.glassBorder)
                AxisValueLabel()
                    .foregroundStyle(Color.secondaryText)
                    .font(.caption)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 5)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        VStack(spacing: 2) {
                            Text(date, format: .dateTime.day())
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(date, format: .dateTime.month(.abbreviated))
                                .font(.caption2)
                        }
                        .foregroundStyle(Color.secondaryText)
                    }
                    AxisGridLine()
                        .foregroundStyle(Color.glassBorder)
                }
            }
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleChartTap(location: location, geometry: geometry, chartProxy: chartProxy)
                    }
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: 30 * 24 * 60 * 60)
    }
    
    private var legendView: some View {
        HStack(spacing: 24) {
            // Systolic legend
            HStack(spacing: 8) {
                Circle()
                    .fill(LinearGradient.systolicGradient)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Systolic")
                        .font(.caption)
                        .foregroundColor(.primaryText)
                    
                    if let avgSys = averageSystolic {
                        Text("Avg: \(avgSys)")
                            .font(.caption2)
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            
            // Diastolic legend
            HStack(spacing: 8) {
                Circle()
                    .fill(LinearGradient.diastolicGradient)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Diastolic")
                        .font(.caption)
                        .foregroundColor(.primaryText)
                    
                    if let avgDia = averageDiastolic {
                        Text("Avg: \(avgDia)")
                            .font(.caption2)
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            
            Spacer()
            
            // Chart info
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(filteredReadingsCount) readings")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Text("Scroll for more →")
                    .font(.caption2)
                    .foregroundColor(.tertiaryText)
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func tooltipView(for point: BPChartPoint) -> some View {
        VStack(spacing: 4) {
            Text(point.date, format: .dateTime.month().day())
                .font(.caption)
                .fontWeight(.semibold)
            
            Text("\(Int(point.value)) \(point.type == .systolic ? "SYS" : "DIA")")
                .font(.caption2)
                .foregroundColor(point.type == .systolic ? Color.systolicGradientStart : Color.diastolicGradientStart)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.glassBorder, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Helper Methods
    
    private func handleChartTap(location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        let xPosition = location.x - geometry.frame(in: .local).minX
        let plotWidth = geometry.size.width
        let dataPointCount = CGFloat(chartData.count / 2) // Divided by 2 because we have systolic and diastolic
        
        guard dataPointCount > 0 else { return }
        
        let pointIndex = Int((xPosition / plotWidth) * dataPointCount)
        
        if pointIndex >= 0 && pointIndex < chartData.count {
            withAnimation(.spring(response: 0.3)) {
                // Find the closest point
                let targetDate = chartData[pointIndex].date
                if let closest = chartData.min(by: { abs($0.date.timeIntervalSince(targetDate)) < abs($1.date.timeIntervalSince(targetDate)) }) {
                    selectedPoint = selectedPoint?.id == closest.id ? nil : closest
                }
            }
        }
    }
    
    private func updateChartData() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -windowDays, to: endDate)!
        
        dateRange = startDate...endDate
        
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
    
    // MARK: - Computed Properties
    
    private var averageSystolic: Int? {
        let systolicData = chartData.filter { $0.type == .systolic }
        guard !systolicData.isEmpty else { return nil }
        return Int(systolicData.map(\.value).reduce(0, +) / Double(systolicData.count))
    }
    
    private var averageDiastolic: Int? {
        let diastolicData = chartData.filter { $0.type == .diastolic }
        guard !diastolicData.isEmpty else { return nil }
        return Int(diastolicData.map(\.value).reduce(0, +) / Double(diastolicData.count))
    }
    
    private var filteredReadingsCount: Int {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -windowDays, to: endDate)!
        return readings.filter { $0.date >= startDate && $0.date <= endDate }.count
    }
}

// Keep the existing BPChartPoint struct
struct BPChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let type: BPType
    
    enum BPType {
        case systolic, diastolic
    }
}
