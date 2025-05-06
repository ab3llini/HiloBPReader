import SwiftUI
import Charts

struct BloodPressureLineChart: View {
    let data: [BloodPressureReading]
    let showMorning: Bool
    let showEvening: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Blood Pressure Trend")
                .font(.headline)
            
            if data.isEmpty {
                EmptyChartView()
            } else {
                Chart {
                    // Threshold areas
                    if let minDate = data.map({ $0.date }).min(),
                       let maxDate = data.map({ $0.date }).max() {
                        // Hypertension Stage 1 to 2 area
                        RectangleMark(
                            xStart: .value("Start", minDate),
                            xEnd: .value("End", maxDate),
                            yStart: .value("Hypertension Stage 1", 140),
                            yEnd: .value("Hypertension Stage 2", 160)
                        )
                        .foregroundStyle(Color.red.opacity(0.1))
                        
                        // Elevated to Hypertension Stage 1 area
                        RectangleMark(
                            xStart: .value("Start", minDate),
                            xEnd: .value("End", maxDate),
                            yStart: .value("Elevated", 120),
                            yEnd: .value("Hypertension Stage 1", 140)
                        )
                        .foregroundStyle(Color.orange.opacity(0.1))
                    }
                    
                    
                    // Systolic readings
                    ForEach(filteredData) { reading in
                        PointMark(
                            x: .value("Date", reading.date),
                            y: .value("SYS", reading.systolic)
                        )
                        .foregroundStyle(isEvening(reading) ? .orange.opacity(0.8) : .red.opacity(0.8))
                        .symbol(isEvening(reading) ? .diamond : .circle)
                        
                        LineMark(
                            x: .value("Date", reading.date),
                            y: .value("SYS", reading.systolic)
                        )
                        .foregroundStyle(.red.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                    
                    // Diastolic readings
                    ForEach(filteredData) { reading in
                        PointMark(
                            x: .value("Date", reading.date),
                            y: .value("DIA", reading.diastolic)
                        )
                        .foregroundStyle(isEvening(reading) ? .indigo.opacity(0.8) : .blue.opacity(0.8))
                        .symbol(isEvening(reading) ? .diamond : .circle)
                        
                        LineMark(
                            x: .value("Date", reading.date),
                            y: .value("DIA", reading.diastolic)
                        )
                        .foregroundStyle(.blue.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                    
                    // Reference lines
                    RuleMark(y: .value("SYS Normal", 120))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        
                    RuleMark(y: .value("DIA Normal", 80))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                .chartYScale(domain: 40...180)
                .chartYAxis {
                    AxisMarks(preset: .extended, position: .leading)
                }
                .chartXAxis {
                    AxisMarks(preset: .automatic)
                }
                .chartLegend(position: .bottom)
            }
        }
    }
    
    private var filteredData: [BloodPressureReading] {
        data.filter { reading in
            let hour = Calendar.current.component(.hour, from: reading.date)
            let isMorning = hour >= 5 && hour < 12
            let isEvening = hour >= 17 && hour < 23
            
            if isMorning && showMorning {
                return true
            }
            if isEvening && showEvening {
                return true
            }
            if !isMorning && !isEvening {
                return true
            }
            return false
        }
    }
    
    private func isEvening(_ reading: BloodPressureReading) -> Bool {
        let hour = Calendar.current.component(.hour, from: reading.date)
        return hour >= 17 && hour < 23
    }
}
