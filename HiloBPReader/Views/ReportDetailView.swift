import SwiftUI

struct ReportDetailView: View {
    let report: BloodPressureReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("User: \(report.memberName)")
                        .font(.headline)
                    Text("Period: \(report.month) \(report.year)")
                }
                Spacer()
            }
            .padding(.horizontal)
            
            if let stats = report.summaryStats {
                HStack {
                    StatView(title: "SYS", value: "\(stats.overallSystolicMean)")
                    StatView(title: "DIA", value: "\(stats.overallDiastolicMean)")
                    StatView(title: "HR", value: "\(stats.overallHeartRateMean)")
                }
                .padding()
            }
            
            Text("Readings (\(report.readings.count))")
                .font(.headline)
                .padding(.horizontal)
            
            List {
                ForEach(report.readings) { reading in
                    ReadingRowView(reading: reading)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
