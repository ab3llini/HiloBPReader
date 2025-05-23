import Foundation
import Combine

@MainActor
class DataStore: ObservableObject {
    @Published var allReadings: [BloodPressureReading] = [] {
        didSet {
            print("📊 allReadings changed: \(oldValue.count) → \(allReadings.count)")
            invalidateCache()
            saveReadingsToStorage()
        }
    }
    
    @Published var currentReport: BloodPressureReport? {
        didSet {
            print("📋 currentReport changed: \(oldValue?.memberName ?? "nil") → \(currentReport?.memberName ?? "nil")")
            saveCurrentReportToStorage()
        }
    }
    
    // MARK: - Storage URLs
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    private var readingsURL: URL {
        documentsDirectory.appendingPathComponent("bp_readings.json")
    }
    
    private var currentReportURL: URL {
        documentsDirectory.appendingPathComponent("current_report.json")
    }
    
    // MARK: - Cache properties
    private var _recentReadings: [BloodPressureReading]?
    private var _latestStats: BPStats?
    private var _cacheInvalidationDate: Date = .distantPast
    private let cacheTimeout: TimeInterval = 60
    
    // MARK: - Initialization
    init() {
        print("🚀 DataStore initializing...")
        loadPersistedData()
    }
    
    // MARK: - Persistence Methods
    private func loadPersistedData() {
        // Load readings
        do {
            let readingsData = try Data(contentsOf: readingsURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedReadings = try decoder.decode([BloodPressureReading].self, from: readingsData)
            
            // Set directly to avoid triggering didSet during init
            self.allReadings = decodedReadings.sorted { $0.date > $1.date }
            print("✅ Loaded \(allReadings.count) readings from storage")
        } catch {
            print("📱 No previous readings found: \(error.localizedDescription)")
            self.allReadings = []
        }
        
        // Load current report
        do {
            let reportData = try Data(contentsOf: currentReportURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.currentReport = try decoder.decode(BloodPressureReport.self, from: reportData)
            print("✅ Loaded current report: \(currentReport?.memberName ?? "Unknown")")
        } catch {
            print("📱 No previous report found: \(error.localizedDescription)")
            self.currentReport = nil
        }
    }
    
    private func saveReadingsToStorage() {
        print("💾 Saving \(allReadings.count) readings...")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(allReadings)
            try data.write(to: readingsURL, options: .atomic)
            print("✅ Successfully saved \(allReadings.count) readings")
        } catch {
            print("❌ Failed to save readings: \(error.localizedDescription)")
        }
    }
    
    private func saveCurrentReportToStorage() {
        guard let report = currentReport else {
            try? FileManager.default.removeItem(at: currentReportURL)
            print("🗑️ Removed current report file")
            return
        }
        
        print("💾 Saving current report: \(report.memberName)")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(report)
            try data.write(to: currentReportURL, options: .atomic)
            print("✅ Successfully saved current report")
        } catch {
            print("❌ Failed to save current report: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    func setCurrentReport(_ report: BloodPressureReport?) {
        print("📋 Setting current report: \(report?.memberName ?? "nil")")
        currentReport = report
        
        if let report = report {
            print("📊 Adding \(report.readings.count) readings from report")
            addReadings(report.readings)
        }
    }
    
    func addReadings(_ newReadings: [BloodPressureReading]) {
        print("📥 Adding \(newReadings.count) new readings...")
        
        let existingIds = Set(allReadings.map(createReadingId))
        
        let uniqueReadings = newReadings.filter { reading in
            let id = createReadingId(reading)
            return !existingIds.contains(id)
        }
        
        print("   Found \(uniqueReadings.count) unique readings")
        
        guard !uniqueReadings.isEmpty else {
            print("   ⚠️ No unique readings to add")
            return
        }
        
        allReadings.append(contentsOf: uniqueReadings)
        allReadings.sort { $0.date > $1.date }
        print("   ✅ Total readings: \(allReadings.count)")
    }
    
    func clearAllData() {
        print("🗑️ Clearing all data...")
        allReadings = []
        currentReport = nil
        
        try? FileManager.default.removeItem(at: readingsURL)
        try? FileManager.default.removeItem(at: currentReportURL)
        print("🗑️ Cleared all data and storage files")
    }
    
    // MARK: - Cached computed properties
    var recentReadings: [BloodPressureReading] {
        if let cached = _recentReadings,
           Date().timeIntervalSince(_cacheInvalidationDate) < cacheTimeout {
            return cached
        }
        
        let recent = Array(
            allReadings
                .sorted(by: { $0.date > $1.date })
                .prefix(10)
        )
        
        _recentReadings = recent
        return recent
    }
    
    var latestStats: BPStats {
        if let cached = _latestStats,
           Date().timeIntervalSince(_cacheInvalidationDate) < cacheTimeout {
            return cached
        }
        
        let stats = calculateStats()
        _latestStats = stats
        return stats
    }
    
    // MARK: - Helper methods
    private func calculateStats() -> BPStats {
        guard !allReadings.isEmpty else {
            return BPStats(systolicMean: 0, diastolicMean: 0, heartRateMean: 0)
        }
        
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        
        let recentReadings = allReadings.lazy
            .filter { $0.date >= thirtyDaysAgo }
            .prefix(100)
        
        let readingsArray = Array(recentReadings)
        
        guard !readingsArray.isEmpty else {
            let fallbackReadings = Array(allReadings.prefix(10))
            return calculateStatsFromReadings(fallbackReadings)
        }
        
        return calculateStatsFromReadings(readingsArray)
    }
    
    private func calculateStatsFromReadings(_ readings: [BloodPressureReading]) -> BPStats {
        guard !readings.isEmpty else {
            return BPStats(systolicMean: 0, diastolicMean: 0, heartRateMean: 0)
        }
        
        let systolicValues = readings.map(\.systolic)
        let diastolicValues = readings.map(\.diastolic)
        let heartRateValues = readings.map(\.heartRate)
        
        let systolicMean = systolicValues.reduce(0, +) / readings.count
        let diastolicMean = diastolicValues.reduce(0, +) / readings.count
        let heartRateMean = heartRateValues.reduce(0, +) / readings.count
        
        return BPStats(
            systolicMean: systolicMean,
            diastolicMean: diastolicMean,
            heartRateMean: heartRateMean
        )
    }
    
    private func invalidateCache() {
        _recentReadings = nil
        _latestStats = nil
        _cacheInvalidationDate = Date()
    }
    
    private func createReadingId(_ reading: BloodPressureReading) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH:mm"
        let dateString = formatter.string(from: reading.date)
        return "\(dateString)-\(reading.systolic)-\(reading.diastolic)-\(reading.heartRate)"
    }
}

// MARK: - Stats model
struct BPStats {
    let systolicMean: Int
    let diastolicMean: Int
    let heartRateMean: Int
    
    var classification: BPClassification {
        BPClassificationService.shared.classify(
            systolic: systolicMean,
            diastolic: diastolicMean
        )
    }
    
    var isEmpty: Bool {
        systolicMean == 0 && diastolicMean == 0 && heartRateMean == 0
    }
    
    var formattedSummary: String {
        guard !isEmpty else { return "No data available" }
        return "\(systolicMean)/\(diastolicMean) mmHg"
    }
}
