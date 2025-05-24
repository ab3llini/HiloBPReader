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
    
    // Track all imported reports for metadata purposes (optional)
    @Published var importedReports: [ImportedReportMetadata] = [] {
        didSet {
            saveReportMetadataToStorage()
        }
    }
    
    // MARK: - Storage URLs
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    private var readingsURL: URL {
        documentsDirectory.appendingPathComponent("bp_readings.json")
    }
    
    private var reportsMetadataURL: URL {
        documentsDirectory.appendingPathComponent("imported_reports.json")
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
        
        // Load report metadata (optional)
        do {
            let metadataData = try Data(contentsOf: reportsMetadataURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.importedReports = try decoder.decode([ImportedReportMetadata].self, from: metadataData)
            print("✅ Loaded \(importedReports.count) report metadata entries")
        } catch {
            print("📱 No previous report metadata found: \(error.localizedDescription)")
            self.importedReports = []
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
    
    private func saveReportMetadataToStorage() {
        print("💾 Saving report metadata...")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(importedReports)
            try data.write(to: reportsMetadataURL, options: .atomic)
            print("✅ Successfully saved report metadata")
        } catch {
            print("❌ Failed to save report metadata: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    func importReport(_ report: BloodPressureReport) {
        print("📋 Importing report from \(report.month) \(report.year) with \(report.readings.count) readings")
        
        // Add readings
        addReadings(report.readings)
        
        // Track the import metadata
        let metadata = ImportedReportMetadata(
            id: UUID(),
            memberName: report.memberName,
            month: report.month,
            year: report.year,
            importDate: Date(),
            readingCount: report.readings.count
        )
        importedReports.append(metadata)
        
        print("✅ Import complete")
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
        importedReports = []
        
        try? FileManager.default.removeItem(at: readingsURL)
        try? FileManager.default.removeItem(at: reportsMetadataURL)
        print("🗑️ Cleared all data and storage files")
    }
    
    // MARK: - Computed Properties
    var totalReadingsCount: Int {
        allReadings.count
    }
    
    var dateRange: String {
        guard let firstDate = allReadings.map({ $0.date }).min(),
              let lastDate = allReadings.map({ $0.date }).max() else {
            return "No data"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
    }
    
    var uniqueMemberNames: [String] {
        Array(Set(importedReports.map { $0.memberName }))
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

// MARK: - Supporting Models
struct ImportedReportMetadata: Codable, Identifiable {
    let id: UUID
    let memberName: String
    let month: String
    let year: String
    let importDate: Date
    let readingCount: Int
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
