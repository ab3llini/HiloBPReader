import Foundation

struct BloodPressureReading: Identifiable {
    let id = UUID()
    let date: Date
    let time: String
    let systolic: Int
    let diastolic: Int
    let heartRate: Int
    let readingType: ReadingType
    
    enum ReadingType: String {
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
}
