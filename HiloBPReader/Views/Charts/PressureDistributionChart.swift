import SwiftUI
import Charts

struct PressureDistributionChart: View {
    let data: [BloodPressureReading]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BP Distribution")
                .font(.headline)
            
            if data.isEmpty {
                EmptyChartView()
            } else {
                Chart {
                    ForEach(systolicRanges) { range in
                        BarMark(
                            x: .value("Range", "\(range.min)-\(range.max)"),
                            y: .value("Count", countReadings(in: range, isSystolic: true))
                        )
                        .foregroundStyle(.red.opacity(0.7))
                    }
                    
                    ForEach(diastolicRanges) { range in
                        BarMark(
                            x: .value("Range", "\(range.min)-\(range.max)"),
                            y: .value("Count", countReadings(in: range, isSystolic: false))
                        )
                        .foregroundStyle(.blue.opacity(0.7))
                    }
                }
                .chartXAxis {
                    AxisMarks {
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .chartForegroundStyleScale([
                    "Systolic": Color.red.opacity(0.7),
                    "Diastolic": Color.blue.opacity(0.7)
                ])
                .chartLegend(position: .bottom)
            }
        }
    }
    
    private var systolicRanges: [BPRange] {
        [
            BPRange(id: 1, min: 100, max: 119, label: "Normal"),
            BPRange(id: 2, min: 120, max: 129, label: "Elevated"),
            BPRange(id: 3, min: 130, max: 139, label: "Stage 1"),
            BPRange(id: 4, min: 140, max: 159, label: "Stage 2"),
            BPRange(id: 5, min: 160, max: 180, label: "Crisis")
        ]
    }
    
    private var diastolicRanges: [BPRange] {
        [
            BPRange(id: 6, min: 60, max: 79, label: "Normal"),
            BPRange(id: 7, min: 80, max: 89, label: "Stage 1"),
            BPRange(id: 8, min: 90, max: 99, label: "Stage 2"),
            BPRange(id: 9, min: 100, max: 120, label: "Crisis")
        ]
    }
    
    private func countReadings(in range: BPRange, isSystolic: Bool) -> Int {
        data.filter { reading in
            let value = isSystolic ? reading.systolic : reading.diastolic
            return value >= range.min && value <= range.max
        }.count
    }
}

struct BPRange: Identifiable {
    let id: Int
    let min: Int
    let max: Int
    let label: String
}
