import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    
    private let healthStore = HKHealthStore()
    private let bloodPressureSystolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
    private let bloodPressureDiastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var syncStatus: SyncStatus = .idle
    
    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
    }
    
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case completed(Int)
        case failed(Error?)
        
        static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle):
                return true
            case (.syncing, .syncing):
                return true
            case (.completed(let count1), .completed(let count2)):
                return count1 == count2
            case (.failed(_), .failed(_)):
                // Consider all errors equal for comparison purposes
                return true
            default:
                return false
            }
        }
    }
    
    func requestAuthorization() {
        let typesToWrite: Set<HKSampleType> = [
            bloodPressureSystolicType,
            bloodPressureDiastolicType,
            heartRateType
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToWrite) { success, error in
            DispatchQueue.main.async {
                self.authorizationStatus = success ? .authorized : .denied
            }
        }
    }
    
    func saveReading(_ reading: BloodPressureReading, completion: @escaping (Bool, Error?) -> Void) {
        // Create date components for precise time
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let timeDate = dateFormatter.date(from: reading.time) else {
            completion(false, nil)
            return
        }
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: reading.date)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        guard let combinedDate = calendar.date(from: combinedComponents) else {
            completion(false, nil)
            return
        }
        
        // Create the correlation
        let systolicValue = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: Double(reading.systolic))
        let diastolicValue = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: Double(reading.diastolic))
        
        let systolicSample = HKQuantitySample(
            type: bloodPressureSystolicType,
            quantity: systolicValue,
            start: combinedDate,
            end: combinedDate
        )
        
        let diastolicSample = HKQuantitySample(
            type: bloodPressureDiastolicType,
            quantity: diastolicValue,
            start: combinedDate,
            end: combinedDate
        )
        
        let objects: Set<HKSample> = [systolicSample, diastolicSample]
        
        let bloodPressureType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!
        let correlation = HKCorrelation(type: bloodPressureType, start: combinedDate, end: combinedDate, objects: objects)
        
        healthStore.save(correlation) { (success, error) in
            if success {
                // Now save heart rate separately
                let heartRateValue = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: Double(reading.heartRate))
                let heartRateSample = HKQuantitySample(
                    type: self.heartRateType,
                    quantity: heartRateValue,
                    start: combinedDate,
                    end: combinedDate
                )
                
                self.healthStore.save(heartRateSample, withCompletion: completion)
            } else {
                completion(success, error)
            }
        }
    }
    
    func syncReadingsToHealthKit(_ readings: [BloodPressureReading]) {
        guard authorizationStatus == .authorized else { return }
        
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        let group = DispatchGroup()
        var failedCount = 0
        var lastError: Error?
        
        for reading in readings {
            group.enter()
            
            saveReading(reading) { success, error in
                if !success {
                    failedCount += 1
                    lastError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if failedCount == 0 {
                self.syncStatus = .completed(readings.count)
            } else {
                self.syncStatus = .failed(lastError)
            }
        }
    }
}
