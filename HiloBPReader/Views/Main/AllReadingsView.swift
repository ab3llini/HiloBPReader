import SwiftUI

struct AllReadingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var searchText = ""
    
    var body: some View {
        List {
            ForEach(filteredReadings) { reading in
                ReadingRowView(reading: reading)
            }
        }
        .navigationTitle("All Readings")
        .searchable(text: $searchText, prompt: "Search readings")
        .background(Color.mainBackground.ignoresSafeArea())
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
}

struct ReadingRowView: View {
    let reading: BloodPressureReading
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.subheadline)
                Text(reading.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                BPValueView(value: reading.systolic, label: "SYS", color: systolicColor)
                BPValueView(value: reading.diastolic, label: "DIA", color: diastolicColor)
                BPValueView(value: reading.heartRate, label: "BPM", color: .primary)
            }
            
            if reading.readingType != .normal {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
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
        .frame(width: 40)
    }
}
