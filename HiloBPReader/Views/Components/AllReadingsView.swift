import SwiftUI

struct AllReadingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var searchText = ""
    @State private var showingAdvancedFilters = false
    @State private var selectedClassification: BPClassification?
    
    var body: some View {
        VStack {
            // Add advanced filters section
            if showingAdvancedFilters {
                advancedFiltersView
                    .transition(.opacity)
            }
            
            List {
                ForEach(groupedReadings, id: \.date) { group in
                    Section(header: dateHeader(for: group.date)) {
                        ForEach(group.readings) { reading in
                            ReadingRowView(reading: reading)
                        }
                    }
                }
                
                if groupedReadings.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                
                                Text("No readings match your search")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                if !searchText.isEmpty {
                                    Button("Clear Search") {
                                        searchText = ""
                                        selectedClassification = nil
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("All Readings")
            .searchable(text: $searchText, prompt: "Search by date, values, or status")
            .background(Color.mainBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            showingAdvancedFilters.toggle()
                        }
                    }) {
                        Label(showingAdvancedFilters ? "Hide Filters" : "Filter",
                              systemImage: showingAdvancedFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
    
    private var advancedFiltersView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter by Classification")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: {
                        selectedClassification = nil
                    }) {
                        Text("All")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedClassification == nil ? Color.blue : Color.secondary.opacity(0.2))
                            .foregroundColor(selectedClassification == nil ? .white : .primary)
                            .cornerRadius(16)
                    }
                    
                    ForEach([BPClassification.normal, .elevated, .hypertensionStage1, .hypertensionStage2, .crisis]) { classification in
                        Button(action: {
                            selectedClassification = classification
                        }) {
                            HStack {
                                Circle()
                                    .fill(classification.color)
                                    .frame(width: 8, height: 8)
                                Text(classification.rawValue)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedClassification == classification ? classification.color : Color.secondary.opacity(0.2))
                            .foregroundColor(selectedClassification == classification ? .white : .primary)
                            .cornerRadius(16)
                        }
                    }
                }
            }
            
            Divider()
        }
        .padding()
        .background(Color.secondaryBackground)
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
        var readings = dataStore.allReadings
        
        // First apply classification filter if selected
        if let classification = selectedClassification {
            readings = readings.filter { reading in
                let readingClassification = BPClassificationService.shared.classify(
                    systolic: reading.systolic,
                    diastolic: reading.diastolic
                )
                return readingClassification == classification
            }
        }
        
        // Then apply text search if any
        if searchText.isEmpty {
            return readings.sorted(by: { $0.date > $1.date })
        } else {
            return readings.filter { reading in
                // Format date for searching
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy"
                let dateString = dateFormatter.string(from: reading.date)
                
                // Get classification for this reading
                let classification = BPClassificationService.shared.classify(
                    systolic: reading.systolic,
                    diastolic: reading.diastolic
                )
                
                // Create a combined string of all searchable terms
                let searchableText = [
                    dateString.lowercased(),
                    reading.time.lowercased(),
                    "\(reading.systolic)",
                    "\(reading.diastolic)",
                    "\(reading.heartRate)",
                    classification.rawValue.lowercased(),
                    reading.readingType.rawValue.lowercased()
                ].joined(separator: " ")
                
                // Check direct matches
                if searchableText.localizedCaseInsensitiveContains(searchText.lowercased()) {
                    return true
                }
                
                // Check if search term matches a classification
                if let matchedClassification = BPClassificationService.shared.matchesClassification(searchTerm: searchText),
                   matchedClassification == classification {
                    return true
                }
                
                // Not a match
                return false
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
    
    // Get classification from central service
    private var classification: BPClassification {
        BPClassificationService.shared.classify(
            systolic: reading.systolic,
            diastolic: reading.diastolic
        )
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(reading.time)
                    .font(.headline)
                
                if reading.readingType != .normal {
                    readingTypeLabel
                }
                
                // Add the classification label - NEW
                HStack {
                    Circle()
                        .fill(classification.color)
                        .frame(width: 8, height: 8)
                    Text(classification.rawValue)
                        .font(.caption)
                        .foregroundColor(classification.color)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                BPValueView(
                    value: reading.systolic,
                    label: "SYS",
                    color: BPClassificationService.shared.systolicColor(reading.systolic)
                )
                BPValueView(
                    value: reading.diastolic,
                    label: "DIA",
                    color: BPClassificationService.shared.diastolicColor(reading.diastolic)
                )
                BPValueView(
                    value: reading.heartRate,
                    label: "BPM",
                    color: BPClassificationService.shared.heartRateColor(reading.heartRate)
                )
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
