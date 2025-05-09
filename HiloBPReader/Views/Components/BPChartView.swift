import SwiftUI
import Charts

// The actual chart component
struct BPChartView: View {
    let data: [BPDataPoint]
    let dateRange: ClosedRange<Date>
    
    var body: some View {
        Chart {
            // Reference lines only
            ReferenceLines()
            
            // Add data markers
            DataMarkers(data: data)
        }
        .chartYScale(domain: 60...160)
        .chartXScale(domain: dateRange)
        .chartYAxis {
            AxisMarks(values: [60, 80, 120, 140, 160]) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month().day())
                            .font(.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 180)
        .padding()
        .background(Color.secondaryBackground)
        .cornerRadius(16)
        .padding(.horizontal)
        // Add animation for smooth transitions
        .animation(.easeInOut(duration: 0.2), value: dateRange.lowerBound)
        .animation(.easeInOut(duration: 0.2), value: dateRange.upperBound)
        // Make sure users know this is scrollable
        .overlay(alignment: .trailing) {
            Image(systemName: "arrow.left.and.right")
                .foregroundColor(.secondary.opacity(0.7))
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(8)
        }
    }
}

// Reference lines component
struct ReferenceLines: ChartContent {
    var body: some ChartContent {
        RuleMark(y: .value("Normal Systolic", 120))
            .foregroundStyle(.green.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        
        RuleMark(y: .value("Normal Diastolic", 80))
            .foregroundStyle(.green.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
    }
}

// Data markers component
struct DataMarkers: ChartContent {
    let data: [BPDataPoint]
    
    var body: some ChartContent {
        ForEach(data) { item in
            // Vertical line for std deviation
            if item.stdDev > 0 {
                RuleMark(
                    x: .value("Date", item.date),
                    yStart: .value("Lower", item.value - item.stdDev),
                    yEnd: .value("Upper", item.value + item.stdDev)
                )
                .foregroundStyle(item.color.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            
            // Points for mean values
            PointMark(
                x: .value("Date", item.date),
                y: .value("Value", item.value)
            )
            .foregroundStyle(item.color)
            .symbolSize(30)
        }
    }
}
