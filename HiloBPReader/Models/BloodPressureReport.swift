import Foundation

struct BloodPressureReport: Identifiable, Codable {
    let id: UUID
    let memberName: String
    let email: String
    let month: String
    let year: String
    let gender: String
    let dateOfBirth: String
    let height: String
    let weight: String
    
    var summaryStats: SummaryStats?
    var readings: [BloodPressureReading]
    
    struct SummaryStats: Codable {
        let daytimeSystolicMean: Int
        let daytimeDiastolicMean: Int
        let daytimeHeartRateMean: Int
        let nighttimeSystolicMean: Int
        let nighttimeDiastolicMean: Int
        let nighttimeHeartRateMean: Int
        let overallSystolicMean: Int
        let overallDiastolicMean: Int
        let overallHeartRateMean: Int
    }
    
    // Custom initializer to keep the existing constructor pattern
    init(memberName: String, email: String, month: String, year: String, gender: String,
         dateOfBirth: String, height: String, weight: String, summaryStats: SummaryStats?, readings: [BloodPressureReading]) {
        self.id = UUID()
        self.memberName = memberName
        self.email = email
        self.month = month
        self.year = year
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.height = height
        self.weight = weight
        self.summaryStats = summaryStats
        self.readings = readings
    }
}
