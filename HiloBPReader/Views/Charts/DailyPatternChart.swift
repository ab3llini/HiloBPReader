import SwiftUI
import Charts

struct DailyPatternChart: View {
    let data: [HourlyBPData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Pattern")
                .font(.headline)
                .padding(.leading, 4)
            
            if data.isEmpty {
                EmptyChartView()
            } else {
                Chart {
                    // Background time periods - night time
                    let minY = 60
                    let maxY = 180
                    RectangleMark(
                        xStart: .value("Sleep Start", 0),
                        xEnd: .value("Sleep End", 6),
                        yStart: .value("Min Y", minY),
                        yEnd: .value("Max Y", maxY)
                    )
                    .foregroundStyle(Color.purple.opacity(0.07))

                    RectangleMark(
                        xStart: .value("Evening Start", 20),
                        xEnd: .value("Evening End", 24),
                        yStart: .value("Min Y", minY),
                        yEnd: .value("Max Y", maxY)
                    )
                    .foregroundStyle(Color.purple.opacity(0.07))
                    
                    // Chronologically sort data
                    let sortedData = data.sorted(by: { $0.hour < $1.hour })
                    
                    // Systolic line
                    ForEach(Array(sortedData.enumerated()), id: \.element.id) { index, hourData in
                        if index > 0 {
                            LineMark(
                                x: .value("Hour", hourData.hour),
                                y: .value("SYS", hourData.systolicAverage)
                            )
                            .foregroundStyle(.red.opacity(0.9))
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        
                        PointMark(
                            x: .value("Hour", hourData.hour),
                            y: .value("SYS", hourData.systolicAverage)
                        )
                        .foregroundStyle(.red)
                        .annotation(position: .top, alignment: .center, spacing: 0) {
                            if [6, 12, 18, 22].contains(hourData.hour) {
                                Text("\(hourData.systolicAverage)")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .padding(2)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(2)
                            }
                        }
                    }
                    
                    // Diastolic line - separate for clean appearance
                    ForEach(Array(sortedData.enumerated()), id: \.element.id) { index, hourData in
                        if index > 0 {
                            LineMark(
                                x: .value("Hour", hourData.hour),
                                y: .value("DIA", hourData.diastolicAverage)
                            )
                            .foregroundStyle(.blue.opacity(0.9))
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        
                        PointMark(
                            x: .value("Hour", hourData.hour),
                            y: .value("DIA", hourData.diastolicAverage)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartYScale(domain: 60...180)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .stride(by: 20)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 6)) { value in
                        AxisGridLine()
                        AxisTick()
                        if let hour = value.as(Int.self) {
                            let hourValue = hour % 12
                            let hourText = hourValue == 0 ? "12" : "\(hourValue)"
                            let ampm = hour < 12 ? "AM" : "PM"
                            
                            AxisValueLabel {
                                Text("\(hourText) \(ampm)")
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
                .frame(height: 200)
                .padding(.top, 4)
            }
        }
    }
}
