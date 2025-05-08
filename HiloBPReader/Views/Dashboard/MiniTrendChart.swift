import SwiftUI
import Charts

struct BPRange: Identifiable {
    let id: Int
    let min: Int
    let max: Int
    let label: String
    
    init(id: Int, min: Int, max: Int, label: String) {
        self.id = id
        self.min = min
        self.max = max
        self.label = label
    }
}

struct DailyBPData: Identifiable, Codable {
    let id: UUID
    let date: Date
    let systolicAverage: Int
    let diastolicAverage: Int
    let heartRateAverage: Int
    let readingCount: Int
    
    init(date: Date, systolicAverage: Int, diastolicAverage: Int, heartRateAverage: Int, readingCount: Int) {
        self.id = UUID()
        self.date = date
        self.systolicAverage = systolicAverage
        self.diastolicAverage = diastolicAverage
        self.heartRateAverage = heartRateAverage
        self.readingCount = readingCount
    }
}

struct BPStats: Identifiable, Codable {
    let id: UUID
    let systolicMean: Int
    let diastolicMean: Int
    let heartRateMean: Int
    
    init(systolicMean: Int, diastolicMean: Int, heartRateMean: Int) {
        self.id = UUID()
        self.systolicMean = systolicMean
        self.diastolicMean = diastolicMean
        self.heartRateMean = heartRateMean
    }
}

struct HourlyBPData: Identifiable, Codable {
    let id: UUID
    let hour: Int
    let systolicAverage: Int
    let diastolicAverage: Int
    let readingCount: Int
    
    init(hour: Int, systolicAverage: Int, diastolicAverage: Int, readingCount: Int) {
        self.id = UUID()
        self.hour = hour
        self.systolicAverage = systolicAverage
        self.diastolicAverage = diastolicAverage
        self.readingCount = readingCount
    }
    
    var hourString: String {
        let hourInt = hour % 12
        let hourText = hourInt == 0 ? "12" : "\(hourInt)"
        let ampm = hour < 12 ? "AM" : "PM"
        return "\(hourText) \(ampm)"
    }
}

struct MiniTrendChart: View {
    let data: [DailyBPData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Trend")
                .font(.headline)
                .padding(.horizontal, 8)
            
            if data.isEmpty {
                EmptyChartView()
            } else {
                Chart {
                    // Create separate entries for systolic and diastolic to avoid connecting them
                    let sortedData = data.sorted(by: { $0.date < $1.date })
                    
                    // Systolic
                    ForEach(Array(sortedData.enumerated()), id: \.element.id) { index, daily in
                        if index > 0 && daily.systolicAverage > 0 {
                            LineMark(
                                x: .value("Date", daily.date),
                                y: .value("SYS", daily.systolicAverage)
                            )
                            .foregroundStyle(.red)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                        
                        if daily.systolicAverage > 0 {
                            PointMark(
                                x: .value("Date", daily.date),
                                y: .value("SYS", daily.systolicAverage)
                            )
                            .foregroundStyle(.red)
                            .symbolSize(30)
                        }
                    }
                    
                    // Diastolic (separate loop to prevent connecting with systolic)
                    ForEach(Array(sortedData.enumerated()), id: \.element.id) { index, daily in
                        if index > 0 && daily.diastolicAverage > 0 {
                            LineMark(
                                x: .value("Date", daily.date),
                                y: .value("DIA", daily.diastolicAverage)
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                        
                        if daily.diastolicAverage > 0 {
                            PointMark(
                                x: .value("Date", daily.date),
                                y: .value("DIA", daily.diastolicAverage)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(30)
                        }
                    }
                    
                    // Threshold lines
                    RuleMark(y: .value("SYS Threshold", 140))
                        .foregroundStyle(.red.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    
                    RuleMark(y: .value("DIA Threshold", 90))
                        .foregroundStyle(.blue.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                .chartYScale(domain: 40...180)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .stride(by: 30)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.weekday(.abbreviated))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading) {
                    HStack(spacing: 20) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("Systolic")
                                .font(.caption)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text("Diastolic")
                                .font(.caption)
                        }
                    }
                }
                .frame(height: 180)
            }
        }
    }
}
