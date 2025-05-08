import SwiftUI
import Charts

struct PressureDistributionChart: View {
    let data: [BloodPressureReading]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BP Distribution")
                .font(.headline)
                .padding(.leading, 4)
            
            if data.isEmpty {
                EmptyChartView()
            } else {
                Chart {
                    // Systolic ranges
                    ForEach(systolicRanges) { range in
                        BarMark(
                            x: .value("Range", range.id),
                            y: .value("Count", countReadings(in: range, isSystolic: true))
                        )
                        .foregroundStyle(.red.opacity(0.8))
                        .cornerRadius(4)
                    }
                    
                    // Diastolic ranges
                    ForEach(diastolicRanges) { range in
                        BarMark(
                            x: .value("Range", range.id + 10), // Offset to separate from systolic
                            y: .value("Count", countReadings(in: range, isSystolic: false))
                        )
                        .foregroundStyle(.blue.opacity(0.8))
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom, values: [1, 2, 3, 4, 5, 16, 17, 18, 19]) { value in
                        AxisValueLabel {
                            if let id = value.as(Int.self) {
                                if id <= 5 {
                                    let range = systolicRanges.first(where: { $0.id == id })
                                    Text("\(range?.min ?? 0)-\(range?.max ?? 0)")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                } else if id >= 16 {
                                    let range = diastolicRanges.first(where: { $0.id + 10 == id })
                                    Text("\(range?.min ?? 0)-\(range?.max ?? 0)")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let count = value.as(Int.self) {
                                Text("\(count)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom) {
                    HStack(spacing: 20) {
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(.red.opacity(0.8))
                                .frame(width: 12, height: 12)
                            Text("Systolic")
                                .font(.caption)
                        }
                        
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(.blue.opacity(0.8))
                                .frame(width: 12, height: 12)
                            Text("Diastolic")
                                .font(.caption)
                        }
                    }
                }
                .frame(height: 180)
                .padding(.top, 4)
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
