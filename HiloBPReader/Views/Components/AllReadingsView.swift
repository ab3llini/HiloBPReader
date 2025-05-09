import SwiftUI

struct AllReadingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var searchText = ""
    
    var body: some View {
        List {
            ForEach(groupedReadings, id: \.date) { group in
                Section(header: dateHeader(for: group.date)) {
                    ForEach(group.readings) { reading in
                        ReadingRowView(reading: reading)
                    }
                }
            }
        }
        .navigationTitle("All Readings")
        .searchable(text: $searchText, prompt: "Search readings")
        .background(Color.mainBackground.ignoresSafeArea())
    }
    
    // Group readings by date (day)
    private var groupedReadings: [ReadingGroup] {
        let calendar = Calendar.current
        
        // First get filtered readings
        let readings = filteredReadings
        
        // Group by date (day)
        var groupedByDay: [Date: [BloodPressureReading]] = [:]
        
        for reading in readings {
            let day = calendar.startOfDay(for: reading.date)
            if groupedByDay[day] == nil {
                groupedByDay[day] = [reading]
            } else {
                groupedByDay[day]?.append(reading)
            }
        }
        
        // Convert dictionary to array of ReadingGroup
        return groupedByDay.map { (date, readings) in
            ReadingGroup(date: date, readings: readings)
        }.sorted(by: { $0.date > $1.date })
    }
    
    private var filteredReadings: [BloodPressureReading] {
        if searchText.isEmpty {
            return dataStore.allReadings.sorted(by: { $0.date > $1.date })
        } else {
            return dataStore.allReadings.filter { reading in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy"
                let dateString = dateFormatter.string(from: reading.date)
                
                return dateString.localizedCaseInsensitiveContains(searchText) ||
                       reading.time.localizedCaseInsensitiveContains(searchText) ||
                       "\(reading.systolic)".contains(searchText) ||
                       "\(reading.diastolic)".contains(searchText)
            }
            .sorted(by: { $0.date > $1.date })
        }
    }
    
    private func dateHeader(for date: Date) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
        
        return HStack {
            Text(dateFormatter.string(from: date))
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Count of readings for this day
            let count = groupedReadings.first(where: { $0.date == date })?.readings.count ?? 0
            Text("\(count) readings")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Model for grouped readings
struct ReadingGroup {
    let date: Date
    let readings: [BloodPressureReading]
}

struct ReadingRowView: View {
    let reading: BloodPressureReading
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(reading.time)
                    .font(.headline)
                
                if reading.readingType != .normal {
                    readingTypeLabel
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                BPValueView(value: reading.systolic, label: "SYS", color: systolicColor)
                BPValueView(value: reading.diastolic, label: "DIA", color: diastolicColor)
                BPValueView(value: reading.heartRate, label: "BPM", color: .white)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var readingTypeLabel: some View {
        Group {
            switch reading.readingType {
            case .initialization:
                Label("Initialization", systemImage: "target.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            case .cuffMeasurement:
                Label("Cuff", systemImage: "rectangle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            case .onDemandPhone:
                Label("Phone", systemImage: "phone.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            case .normal:
                EmptyView()
            }
        }
    }
    
    private var systolicColor: Color {
        if reading.systolic >= 160 {
            return .red
        } else if reading.systolic >= 140 {
            return .orange
        } else if reading.systolic >= 130 {
            return .yellow
        } else if reading.systolic >= 100 {
            return .green
        } else {
            return .blue // Low BP is blue
        }
    }
    
    private var diastolicColor: Color {
        if reading.diastolic >= 100 {
            return .red
        } else if reading.diastolic >= 90 {
            return .orange
        } else if reading.diastolic >= 85 {
            return .yellow
        } else {
            return .green
        }
    }
}

struct BPValueView: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 44)
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}
