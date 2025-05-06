import Foundation

struct BloodPressureReport: Identifiable {
    let id = UUID()
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
    
    struct SummaryStats {
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
}
