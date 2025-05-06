import SwiftUI
import Charts

struct MiniTrendChart: View {
    let data: [DailyBPData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trend")
                .font(.headline)
            
            Chart {
                ForEach(data) { daily in
                    LineMark(
                        x: .value("Date", daily.date),
                        y: .value("SYS", daily.systolicAverage)
                    )
                    .foregroundStyle(.red.opacity(0.8))
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", daily.date),
                        y: .value("DIA", daily.diastolicAverage)
                    )
                    .foregroundStyle(.blue.opacity(0.8))
                    .interpolationMethod(.catmullRom)
                    
                    // Danger thresholds
                    RuleMark(y: .value("SYS Threshold", 140))
                        .foregroundStyle(.red.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    
                    RuleMark(y: .value("DIA Threshold", 90))
                        .foregroundStyle(.blue.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.weekday(.abbreviated))
                        }
                    }
                }
            }
            .chartLegend(position: .bottom, alignment: .leading) {
                HStack {
                    HStack {
                        Circle()
                            .fill(.red.opacity(0.8))
                            .frame(width: 8, height: 8)
                        Text("Systolic")
                            .font(.caption)
                    }
                    
                    HStack {
                        Circle()
                            .fill(.blue.opacity(0.8))
                            .frame(width: 8, height: 8)
                        Text("Diastolic")
                            .font(.caption)
                    }
                }
            }
        }
    }
}

struct DailyBPData: Identifiable {
    let id = UUID()
    let date: Date
    let systolicAverage: Int
    let diastolicAverage: Int
    let heartRateAverage: Int
    let readingCount: Int
}
