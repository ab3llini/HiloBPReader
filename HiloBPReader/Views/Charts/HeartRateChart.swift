import SwiftUI
import Charts

struct HeartRateChart: View {
    let data: [BloodPressureReading]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Heart Rate")
                .font(.headline)
            
            if data.isEmpty {
                EmptyChartView()
            } else {
                Chart {
                    // Point and line marks for each reading
                    ForEach(data) { reading in
                        LineMark(
                            x: .value("Date", reading.date),
                            y: .value("HR", reading.heartRate)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", reading.date),
                            y: .value("HR", reading.heartRate)
                        )
                        .foregroundStyle(.red)
                    }
                    
                    // Area mark for each reading
                    ForEach(data) { reading in
                        AreaMark(
                            x: .value("Date", reading.date),
                            y: .value("HR", reading.heartRate)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    
                    // Reference range
                    if let minDate = data.map({ $0.date }).min(),
                       let maxDate = data.map({ $0.date }).max() {
                        RectangleMark(
                            xStart: .value("Start", minDate),
                            xEnd: .value("End", maxDate),
                            yStart: .value("Normal Min", 60),
                            yEnd: .value("Normal Max", 80)
                        )
                        .foregroundStyle(.green.opacity(0.1))
                    }
                }
                .chartYScale(domain: 40...100)
                .chartYAxis {
                    AxisMarks(preset: .extended, values: .automatic(desiredCount: 6))
                }
            }
        }
    }
}
