import SwiftUI

struct AllReadingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var searchText = ""
    @State private var showingAdvancedFilters = false
    @State private var selectedClassification: BPClassification?
    @State private var animateList = false
    
    var body: some View {
        ZStack {
            Color.primaryBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom navigation header
                customHeader
                    .padding(.bottom, 16)
                
                // Advanced filters
                if showingAdvancedFilters {
                    advancedFiltersView
                        .transition(.asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal: .push(from: .bottom).combined(with: .opacity)
                        ))
                }
                
                // Main content
                if groupedReadings.isEmpty {
                    emptyStateView
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(groupedReadings, id: \.date) { group in
                                dateSection(for: group)
                                    .transition(.asymmetric(
                                        insertion: .push(from: .leading).combined(with: .opacity),
                                        removal: .push(from: .trailing).combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateList = true
            }
        }
    }
    
    private var customHeader: some View {
        VStack(spacing: 16) {
            // Navigation bar
            HStack {
                Button(action: {
                    // Navigate back
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primaryAccent)
                }
                
                Spacer()
                
                Text("All Readings")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                IconActionButton(
                    icon: showingAdvancedFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle",
                    size: 36,
                    color: showingAdvancedFilters ? .primaryAccent : .secondaryText
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        showingAdvancedFilters.toggle()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Search bar
            searchBar
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondaryText)
            
            TextField("Search by date, values, or status", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.primaryText)
                .accentColor(.primaryAccent)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.glassBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    private var advancedFiltersView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter by Classification")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedClassification == nil,
                        color: .primaryAccent
                    ) {
                        selectedClassification = nil
                    }
                    
                    ForEach([BPClassification.normal, .elevated, .hypertensionStage1, .hypertensionStage2, .crisis]) { classification in
                        FilterChip(
                            title: classification.rawValue,
                            isSelected: selectedClassification == classification,
                            color: classificationColor(classification)
                        ) {
                            selectedClassification = classification
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.secondaryBackground
                .overlay(
                    Rectangle()
                        .fill(Color.glassBorder)
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
    
    private func dateSection(for group: ReadingGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header
            HStack {
                Text(formatDateHeader(group.date))
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("\(group.readings.count) readings")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            .padding(.bottom, 4)
            
            // Readings
            VStack(spacing: 12) {
                ForEach(Array(group.readings.enumerated()), id: \.element.id) { index, reading in
                    HorizontalReadingCard(reading: reading)
                        .opacity(animateList ? 1 : 0)
                        .offset(x: animateList ? 0 : -50)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                            value: animateList
                        )
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: searchText.isEmpty ? "doc.text.magnifyingglass" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primaryAccent, Color.secondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Readings Found" : "No Results")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text(searchText.isEmpty ? "Your readings will appear here once imported" : "Try adjusting your search or filters")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondaryText)
            }
            
            if !searchText.isEmpty || selectedClassification != nil {
                Button(action: {
                    searchText = ""
                    selectedClassification = nil
                }) {
                    Text("Clear Filters")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryAccent)
                }
            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Data Processing
    
    private var groupedReadings: [ReadingGroup] {
        let calendar = Calendar.current
        let readings = filteredReadings
        
        var groupedByDay: [Date: [BloodPressureReading]] = [:]
        
        for reading in readings {
            let day = calendar.startOfDay(for: reading.date)
            if groupedByDay[day] == nil {
                groupedByDay[day] = [reading]
            } else {
                groupedByDay[day]?.append(reading)
            }
        }
        
        return groupedByDay.map { (date, readings) in
            ReadingGroup(date: date, readings: readings)
        }.sorted(by: { $0.date > $1.date })
    }
    
    private var filteredReadings: [BloodPressureReading] {
        var readings = dataStore.allReadings
        
        if let classification = selectedClassification {
            readings = readings.filter { reading in
                let readingClassification = BPClassificationService.shared.classify(
                    systolic: reading.systolic,
                    diastolic: reading.diastolic
                )
                return readingClassification == classification
            }
        }
        
        if searchText.isEmpty {
            return readings.sorted(by: { $0.date > $1.date })
        } else {
            return readings.filter { reading in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy"
                let dateString = dateFormatter.string(from: reading.date)
                
                let classification = BPClassificationService.shared.classify(
                    systolic: reading.systolic,
                    diastolic: reading.diastolic
                )
                
                let searchableText = [
                    dateString.lowercased(),
                    reading.time.lowercased(),
                    "\(reading.systolic)",
                    "\(reading.diastolic)",
                    "\(reading.heartRate)",
                    classification.rawValue.lowercased(),
                    reading.readingType.rawValue.lowercased()
                ].joined(separator: " ")
                
                if searchableText.localizedCaseInsensitiveContains(searchText.lowercased()) {
                    return true
                }
                
                if let matchedClassification = BPClassificationService.shared.matchesClassification(searchTerm: searchText),
                   matchedClassification == classification {
                    return true
                }
                
                return false
            }
            .sorted(by: { $0.date > $1.date })
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func classificationColor(_ classification: BPClassification) -> Color {
        switch classification {
        case .normal: return .bpNormal
        case .elevated: return .bpElevated
        case .hypertensionStage1: return .bpStage1
        case .hypertensionStage2: return .bpStage2
        case .crisis: return .bpCrisis
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

// Keep the existing ReadingGroup struct
struct ReadingGroup {
    let date: Date
    let readings: [BloodPressureReading]
}
