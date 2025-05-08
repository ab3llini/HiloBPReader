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
                .padding(.leading, 4)
            
            if data.isEmpty {
                EmptyChartView()
            } else {
                Chart {
                    // Background zones - green to red gradient for classification
                    if let minDate = data.map({ $0.date }).min(),
                       let maxDate = data.map({ $0.date }).max() {
                        // Normal (<120)
                        RectangleMark(
                            xStart: .value("Start", minDate),
                            xEnd: .value("End", maxDate),
                            yStart: .value("Min", 60),
                            yEnd: .value("Normal", 120)
                        )
                        .foregroundStyle(Color.green.opacity(0.1))
                        
                        // Elevated (120-129)
                        RectangleMark(
                            xStart: .value("Start", minDate),
                            xEnd: .value("End", maxDate),
                            yStart: .value("Normal", 120),
                            yEnd: .value("Elevated", 130)
                        )
                        .foregroundStyle(Color.yellow.opacity(0.1))
                        
                        // Stage 1 (130-139)
                        RectangleMark(
                            xStart: .value("Start", minDate),
                            xEnd: .value("End", maxDate),
                            yStart: .value("Elevated", 130),
                            yEnd: .value("Stage 1", 140)
                        )
                        .foregroundStyle(Color.orange.opacity(0.1))
                        
                        // Stage 2+ (140+)
                        RectangleMark(
                            xStart: .value("Start", minDate),
                            xEnd: .value("End", maxDate),
                            yStart: .value("Stage 1", 140),
                            yEnd: .value("Max", 180)
                        )
                        .foregroundStyle(Color.red.opacity(0.1))
                    }
                    
                    // IMPORTANT: Sort data chronologically and use separate element arrays for clean lines
                    let sortedData = data.sorted(by: { $0.date < $1.date })
                    
                    // Diastolic line
                    let diastolicData = sortedData.filter { reading in
                        let hour = Calendar.current.component(.hour, from: reading.date)
                        let isMorning = hour >= 5 && hour < 12
                        let isEvening = hour >= 17 && hour < 23
                        
                        return (isMorning && showMorning) ||
                               (isEvening && showEvening) ||
                               (!isMorning && !isEvening)
                    }
                    
                    ForEach(Array(diastolicData.enumerated()), id: \.element.id) { index, reading in
                        if index > 0 {
                            LineMark(
                                x: .value("Date", reading.date),
                                y: .value("DIA", reading.diastolic)
                            )
                            .foregroundStyle(Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        
                        PointMark(
                            x: .value("Date", reading.date),
                            y: .value("DIA", reading.diastolic)
                        )
                        .foregroundStyle(isEvening(reading) ? Color.indigo : Color.blue)
                        .symbolSize(30)
                    }
                    
                    // Systolic line (in separate loop to prevent connecting to diastolic)
                    ForEach(Array(diastolicData.enumerated()), id: \.element.id) { index, reading in
                        if index > 0 {
                            LineMark(
                                x: .value("Date", reading.date),
                                y: .value("SYS", reading.systolic)
                            )
                            .foregroundStyle(Color.red)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        
                        PointMark(
                            x: .value("Date", reading.date),
                            y: .value("SYS", reading.systolic)
                        )
                        .foregroundStyle(isEvening(reading) ? Color.pink : Color.red)
                        .symbolSize(30)
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
                    AxisMarks(position: .leading, values: .stride(by: 20)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: calculateStride(for: data))) { value in
                        AxisGridLine()
                        AxisTick()
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(formatDateForAxis(date))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 240)
                .padding(.top, 8)
            }
        }
    }
    
    private func isEvening(_ reading: BloodPressureReading) -> Bool {
        let hour = Calendar.current.component(.hour, from: reading.date)
        return hour >= 17 && hour < 23
    }
    
    private func calculateStride(for data: [BloodPressureReading]) -> Calendar.Component {
        // Find time range
        guard let oldest = data.map({ $0.date }).min(),
              let newest = data.map({ $0.date }).max() else {
            return .day
        }
        
        let timeSpan = newest.timeIntervalSince(oldest)
        let days = timeSpan / (60 * 60 * 24)
        
        if days < 1 {
            return .hour
        } else if days < 7 {
            return .day
        } else if days < 30 {
            return .weekOfMonth
        } else {
            return .month
        }
    }
    
    private func formatDateForAxis(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch calculateStride(for: data) {
        case .hour:
            formatter.dateFormat = "HH:mm"
        case .day:
            formatter.dateFormat = "d MMM"
        case .weekOfMonth:
            formatter.dateFormat = "d MMM"
        case .month:
            formatter.dateFormat = "MMM"
        default:
            formatter.dateFormat = "d MMM"
        }
        
        return formatter.string(from: date)
    }
}
