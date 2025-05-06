import SwiftUI

struct ImportSummaryView: View {
    let report: BloodPressureReport
    let duplicateCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Import Summary")
                .font(.headline)
            
            HStack(spacing: 10) {
                DataBadge(
                    value: "\(report.readings.count)",
                    label: "Readings",
                    icon: "list.bullet",
                    color: .blue
                )
                
                DataBadge(
                    value: dateRange,
                    label: "Date Range",
                    icon: "calendar",
                    color: .purple
                )
                
                if duplicateCount > 0 {
                    DataBadge(
                        value: "\(duplicateCount)",
                        label: "Duplicates",
                        icon: "exclamationmark.triangle",
                        color: .orange
                    )
                }
            }
            
            if duplicateCount > 0 {
                Text("Note: \(duplicateCount) readings appear to be duplicates of readings you've already imported. These will be skipped to avoid duplicates in Apple Health.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            HStack(spacing: 20) {
                Label("User: \(report.memberName)", systemImage: "person")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !report.gender.isEmpty && report.gender != "Unknown" {
                    Label(report.gender, systemImage: "figure.stand")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.secondaryBackground)
        .cornerRadius(12)
    }
    
    private var dateRange: String {
        guard let firstDate = report.readings.map({ $0.date }).min(),
              let lastDate = report.readings.map({ $0.date }).max() else {
            return "N/A"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        return "\(dateFormatter.string(from: firstDate)) - \(dateFormatter.string(from: lastDate))"
    }
}
