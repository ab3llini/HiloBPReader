import Foundation
import Combine

class DataStore: ObservableObject {
    @Published var allReadings: [BloodPressureReading] = [] {
        didSet {
            saveData()
        }
    }
    @Published var currentReport: BloodPressureReport? {
        didSet {
            saveData()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let readingsKey = "com.hilobpreader.readings"
    private let reportKey = "com.hilobpreader.currentReport"
    
    init() {
        loadData()
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        if let savedReadings = userDefaults.data(forKey: readingsKey),
           let decodedReadings = try? JSONDecoder().decode([BloodPressureReading].self, from: savedReadings) {
            allReadings = decodedReadings
        }
        
        if let savedReport = userDefaults.data(forKey: reportKey),
           let decodedReport = try? JSONDecoder().decode(BloodPressureReport.self, from: savedReport) {
            currentReport = decodedReport
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(allReadings) {
            userDefaults.set(encoded, forKey: readingsKey)
        }
        
        if let report = currentReport, let encoded = try? JSONEncoder().encode(report) {
            userDefaults.set(encoded, forKey: reportKey)
        } else {
            userDefaults.removeObject(forKey: reportKey)
        }
    }
    
    // MARK: - Computed Properties
    
    var recentReadings: [BloodPressureReading] {
        return Array(allReadings.sorted(by: { $0.date > $1.date }).prefix(10))
    }
    
    var weeklyTrend: [DailyBPData] {
        // Group readings by day and calculate averages
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        var result: [DailyBPData] = []
        
        // Create date for each day in range
        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Filter readings for this day
            let dayReadings = allReadings.filter {
                $0.date >= dayStart && $0.date < dayEnd
            }
            
            if !dayReadings.isEmpty {
                // Calculate averages
                let sysAvg = Int(dayReadings.map { Double($0.systolic) }.reduce(0, +) / Double(dayReadings.count))
                let diaAvg = Int(dayReadings.map { Double($0.diastolic) }.reduce(0, +) / Double(dayReadings.count))
                let hrAvg = Int(dayReadings.map { Double($0.heartRate) }.reduce(0, +) / Double(dayReadings.count))
                
                let dailyData = DailyBPData(
                    date: dayStart,
                    systolicAverage: sysAvg,
                    diastolicAverage: diaAvg,
                    heartRateAverage: hrAvg,
                    readingCount: dayReadings.count
                )
                
                result.append(dailyData)
            } else {
                // Add empty day for continuity
                result.append(DailyBPData(
                    date: dayStart,
                    systolicAverage: 0,
                    diastolicAverage: 0,
                    heartRateAverage: 0,
                    readingCount: 0
                ))
            }
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return result.filter { $0.readingCount > 0 }
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
    
    var hourlyAverages: [HourlyBPData] {
        // Group readings by hour and calculate averages
        var hourlyData: [Int: [BloodPressureReading]] = [:]
        
        for reading in allReadings {
            let hour = Calendar.current.component(.hour, from: reading.date)
            if hourlyData[hour] == nil {
                hourlyData[hour] = [reading]
            } else {
                hourlyData[hour]?.append(reading)
            }
        }
        
        return hourlyData.map { hour, readings in
            let sysAvg = Int(readings.map { Double($0.systolic) }.reduce(0, +) / Double(readings.count))
            let diaAvg = Int(readings.map { Double($0.diastolic) }.reduce(0, +) / Double(readings.count))
            
            return HourlyBPData(
                hour: hour,
                systolicAverage: sysAvg,
                diastolicAverage: diaAvg,
                readingCount: readings.count
            )
        }.sorted { $0.hour < $1.hour }
    }
    
    // Filter readings based on time frame
    func filteredReadings(for timeFrame: TimeFrame) -> [BloodPressureReading] {
        let calendar = Calendar.current
        let endDate = Date()
        var startDate: Date
        
        switch timeFrame {
        case .day:
            startDate = calendar.date(byAdding: .day, value: -1, to: endDate)!
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
        }
        
        return allReadings.filter { $0.date >= startDate && $0.date <= endDate }
            .sorted(by: { $0.date < $1.date })
    }
    
    func setCurrentReport(_ report: BloodPressureReport?) {
        currentReport = report
        
        if let report = report {
            // Filter out duplicates when adding new readings
            let existingReadingIds = Set(allReadings.map {
                "\($0.date.timeIntervalSince1970)-\($0.systolic)-\($0.diastolic)"
            })
            
            let uniqueNewReadings = report.readings.filter { reading in
                let id = "\(reading.date.timeIntervalSince1970)-\(reading.systolic)-\(reading.diastolic)"
                return !existingReadingIds.contains(id)
            }
            
            // Add new readings to our collection
            allReadings.append(contentsOf: uniqueNewReadings)
        }
    }
}
