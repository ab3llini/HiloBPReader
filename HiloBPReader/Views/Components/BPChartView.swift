import SwiftUI
import Charts

// Keep the original BPDataPoint name for compatibility
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

// The actual chart component (compatible with your existing SimpleBPChart)
struct BPChartView: View {
    let data: [BPDataPoint]
    let dateRange: ClosedRange<Date>
    
    var body: some View {
        Chart(data) { dataPoint in
            // Points for mean values
            PointMark(
                x: .value("Date", dataPoint.date),
                y: .value("Value", dataPoint.value)
            )
            .foregroundStyle(dataPoint.color)
            .symbolSize(30)
            
            // Vertical line for std deviation (if > 0)
            if dataPoint.stdDev > 0 {
                RuleMark(
                    x: .value("Date", dataPoint.date),
                    yStart: .value("Lower", dataPoint.value - dataPoint.stdDev),
                    yEnd: .value("Upper", dataPoint.value + dataPoint.stdDev)
                )
                .foregroundStyle(dataPoint.color.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
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
        // Reference lines overlay
        .overlay {
            Chart {
                RuleMark(y: .value("Normal Systolic", 120))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                
                RuleMark(y: .value("Normal Diastolic", 80))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .chartYScale(domain: 60...160)
            .chartXScale(domain: dateRange)
            .allowsHitTesting(false)
            .frame(height: 180)
            .padding()
            .padding(.horizontal)
        }
        // Scrollable indicator
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
