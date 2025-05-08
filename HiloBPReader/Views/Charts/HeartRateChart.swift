import SwiftUI
import Charts

struct HeartRateChart: View {
    let data: [BloodPressureReading]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Heart Rate")
                .font(.headline)
                .padding(.leading, 4)
            
            if data.isEmpty {
                EmptyChartView()
            } else {
                Chart {
                    // Normal range
                    if let minDate = data.map({ $0.date }).min(),
                       let maxDate = data.map({ $0.date }).max() {
                        RectangleMark(
                            xStart: .value("Start", minDate),
                            xEnd: .value("End", maxDate),
                            yStart: .value("Normal Min", 60),
                            yEnd: .value("Normal Max", 100)
                        )
                        .foregroundStyle(Color.green.opacity(0.08))
                    }
                    
                    // Sort data chronologically
                    let sortedData = data.sorted(by: { $0.date < $1.date })
                    
                    // Area fill below line
                    ForEach(sortedData) { reading in
                        AreaMark(
                            x: .value("Date", reading.date),
                            yStart: .value("Min", 40),
                            yEnd: .value("HR", reading.heartRate)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red.opacity(0.2), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    
                    // Line chart of heart rate - separate line segments for each point
                    ForEach(Array(sortedData.enumerated()), id: \.element.id) { index, reading in
                        if index > 0 {
                            LineMark(
                                x: .value("Date", reading.date),
                                y: .value("HR", reading.heartRate)
                            )
                            .foregroundStyle(Color.red)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        
                        PointMark(
                            x: .value("Date", reading.date),
                            y: .value("HR", reading.heartRate)
                        )
                        .foregroundStyle(Color.red)
                        .symbolSize(30)
                    }
                    
                    // Reference lines
                    RuleMark(y: .value("Normal Min", 60))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        
                    RuleMark(y: .value("Normal Max", 100))
                        .foregroundStyle(.red.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                .chartYScale(domain: 40...120)
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
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
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
                .frame(height: 180)
                .padding(.top, 4)
            }
        }
    }
    
    private func formatDateForAxis(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "d MMM"
        }
        
        return formatter.string(from: date)
    }
}
