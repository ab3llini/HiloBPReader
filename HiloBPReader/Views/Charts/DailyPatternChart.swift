import SwiftUI
import Charts

struct DailyPatternChart: View {
    let data: [HourlyBPData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Pattern")
                .font(.headline)
            
            if data.isEmpty {
                EmptyChartView()
            } else {
                Chart {
                    ForEach(data) { hourData in
                        LineMark(
                            x: .value("Hour", hourData.hour),
                            y: .value("SYS", hourData.systolicAverage)
                        )
                        .foregroundStyle(.red.opacity(0.8))
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Hour", hourData.hour),
                            y: .value("DIA", hourData.diastolicAverage)
                        )
                        .foregroundStyle(.blue.opacity(0.8))
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Hour", hourData.hour),
                            y: .value("SYS", hourData.systolicAverage)
                        )
                        .foregroundStyle(.red)
                        .annotation(position: .top) {
                            if hourData.hour == 8 || hourData.hour == 16 || hourData.hour == 20 {
                                Text("\(hourData.systolicAverage)")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Background time periods
                    RectangleMark(
                        xStart: .value("Sleep Start", 0),
                        xEnd: .value("Sleep End", 6),
                        yStart: .automatic,
                        yEnd: .automatic
                    )
                    .foregroundStyle(Color.purple.opacity(0.1))
                    
                    RectangleMark(
                        xStart: .value("Evening Start", 18),
                        xEnd: .value("Evening End", 24),
                        yStart: .automatic,
                        yEnd: .automatic
                    )
                    .foregroundStyle(Color.purple.opacity(0.1))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 6)) { value in
                        if let hour = value.as(Int.self) {
                            let hourValue = hour % 12
                            let hourText = hourValue == 0 ? "12" : "\(hourValue)"
                            let ampm = hour < 12 ? "AM" : "PM"
                            
                            AxisValueLabel {
                                Text("\(hourText) \(ampm)")
                            }
                        }
                    }
                }
                .chartYScale(domain: 60...180)
                .chartLegend(position: .bottom, alignment: .leading)
            }
        }
    }
}
