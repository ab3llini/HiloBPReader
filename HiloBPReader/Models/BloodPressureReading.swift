import Foundation

struct BloodPressureReading: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let time: String
    let systolic: Int
    let diastolic: Int
    let heartRate: Int
    let readingType: ReadingType
    
    enum ReadingType: String, Codable {
        case normal = ""
        case initialization = "Initialization with cuff"
        case cuffMeasurement = "Cuff measurement"
        case onDemandPhone = "On demand phone measurement"
    }
    
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: date)) \(time)"
    }
    
    // Custom initializer to keep the existing constructor pattern
    init(date: Date, time: String, systolic: Int, diastolic: Int, heartRate: Int, readingType: ReadingType) {
        self.id = UUID()
        self.date = date
        self.time = time
        self.systolic = systolic
        self.diastolic = diastolic
        self.heartRate = heartRate
        self.readingType = readingType
    }
    
    // MARK: - Equatable conformance
    static func == (lhs: BloodPressureReading, rhs: BloodPressureReading) -> Bool {
        return lhs.date == rhs.date &&
               lhs.time == rhs.time &&
               lhs.systolic == rhs.systolic &&
               lhs.diastolic == rhs.diastolic &&
               lhs.heartRate == rhs.heartRate &&
               lhs.readingType == rhs.readingType
    }
}
