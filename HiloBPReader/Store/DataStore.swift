import Foundation
import Combine

class DataStore: ObservableObject {
    @Published var allReadings: [BloodPressureReading] = []
    @Published var currentReport: BloodPressureReport?
    
    // Computed properties for the UI
    var recentReadings: [BloodPressureReading] {
        return Array(allReadings.sorted(by: { $0.date > $1.date }).prefix(10))
    }
    
    var latestStats: BPStats {
        guard !allReadings.isEmpty else {
            return BPStats(systolicMean: 0, diastolicMean: 0, heartRateMean: 0)
        }
        
        // Calculate means from recent readings (last 24 hours)
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        let recentReadings = allReadings.filter { $0.date >= yesterday }
        let readingsToUse = recentReadings.isEmpty ? allReadings : recentReadings
        
        let systolicMean = Int(readingsToUse.map { Double($0.systolic) }.reduce(0, +) / Double(readingsToUse.count))
        let diastolicMean = Int(readingsToUse.map { Double($0.diastolic) }.reduce(0, +) / Double(readingsToUse.count))
        let heartRateMean = Int(readingsToUse.map { Double($0.heartRate) }.reduce(0, +) / Double(readingsToUse.count))
        
        return BPStats(
            systolicMean: systolicMean,
            diastolicMean: diastolicMean,
            heartRateMean: heartRateMean
        )
    }
    
    func setCurrentReport(_ report: BloodPressureReport?) {
        currentReport = report
        
        if let report = report {
            // Add new readings to our collection with deduplication
            addReadings(report.readings)
        }
    }
    
    /// Add readings to the data store with automatic deduplication
    func addReadings(_ newReadings: [BloodPressureReading]) {
        // Create a set of existing reading IDs for O(1) lookup
        let existingReadingIds = Set(allReadings.map { createReadingIdentifier($0) })
        
        // Filter out duplicate readings
        let uniqueNewReadings = newReadings.filter { reading in
            let id = createReadingIdentifier(reading)
            return !existingReadingIds.contains(id)
        }
        
        // Add only unique readings
        if !uniqueNewReadings.isEmpty {
            allReadings.append(contentsOf: uniqueNewReadings)
            
            // Sort readings by date (newest first) after adding new ones
            allReadings.sort(by: { $0.date > $1.date })
        }
    }
    
    /// Create a unique identifier for a reading based on date, time and values
    private func createReadingIdentifier(_ reading: BloodPressureReading) -> String {
        return "\(reading.date.timeIntervalSince1970)-\(reading.systolic)-\(reading.diastolic)-\(reading.heartRate)"
    }
}

// Stats model for BP averages
struct BPStats {
    let systolicMean: Int
    let diastolicMean: Int
    let heartRateMean: Int
}
