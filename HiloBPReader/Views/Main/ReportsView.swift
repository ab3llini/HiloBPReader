import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var isShowingImport = false
    
    var body: some View {
        NavigationView {
            List {
                if let report = dataStore.currentReport {
                    Section(header: Text("Current Report")) {
                        ReportListItem(report: report)
                    }
                    
                    Section(header: Text("Readings")) {
                        ForEach(report.readings) { reading in
                            ReadingListItem(reading: reading)
                        }
                    }
                } else {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Reports",
                        message: "Import a Hilo report to see your readings here"
                    )
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.mainBackground.ignoresSafeArea())
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $isShowingImport) {
                ImportView()
            }
        }
    }
}

struct ReportListItem: View {
    let report: BloodPressureReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(report.memberName)
                .font(.headline)
            
            HStack {
                Label("\(report.month) \(report.year)", systemImage: "calendar")
                Spacer()
                Label("\(report.readings.count) readings", systemImage: "list.bullet")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ReadingListItem: View {
    let reading: BloodPressureReading
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(formattedDate)
                    .font(.subheadline)
                Text(reading.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                VStack {
                    Text("\(reading.systolic)")
                        .font(.headline)
                        .foregroundColor(systolicColor)
                    Text("SYS")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(reading.diastolic)")
                        .font(.headline)
                        .foregroundColor(diastolicColor)
                    Text("DIA")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(reading.heartRate)")
                        .font(.headline)
                    Text("BPM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if reading.readingType != .normal {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: reading.date)
    }
    
    private var systolicColor: Color {
        if reading.systolic >= 140 {
            return .red
        } else if reading.systolic >= 130 {
            return .orange
        }
        return .green
    }
    
    private var diastolicColor: Color {
        if reading.diastolic >= 90 {
            return .red
        } else if reading.diastolic >= 80 {
            return .orange
        }
        return .green
    }
}
