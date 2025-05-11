import Foundation
import HealthKit
import SwiftUI

class HealthKitManager: ObservableObject {
    
    // HealthKit store
    private var healthStore: HKHealthStore?
    
    // Individual quantity types
    private var bloodPressureSystolicType: HKQuantityType?
    private var bloodPressureDiastolicType: HKQuantityType?
    private var heartRateType: HKQuantityType?
    
    // Published properties for UI updates
    @Published var authorizationStatus: AuthorizationStatus = .unknown
    @Published var syncStatus: SyncStatus = .idle
    @Published var existingReadingsCount: Int = 0
    @Published var readingsToSyncCount: Int = 0
    @Published var duplicateReadingsCount: Int = 0
    @Published var showingSyncModal: Bool = false
    @Published var isRequestingPermission: Bool = false
    
    // Track individual permissions
    @Published var hasSystolicPermission: Bool = false
    @Published var hasDiastolicPermission: Bool = false
    @Published var hasHeartRatePermission: Bool = false
    
    enum AuthorizationStatus: String, Equatable {
        case unknown = "unknown"             // We don't know yet
        case notAvailable = "notAvailable"   // HealthKit not available on device
        case notDetermined = "notDetermined" // Permission not yet requested
        case partialAccess = "partialAccess" // Some permissions granted
        case fullAccess = "fullAccess"       // All permissions granted
        case denied = "denied"               // All permissions denied
    }
    
    enum SyncStatus: Equatable {
        case idle
        case checking
        case syncing
        case completed(Int)
        case failed(String)
        
        static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle):
                return true
            case (.checking, .checking):
                return true
            case (.syncing, .syncing):
                return true
            case (.completed(let count1), .completed(let count2)):
                return count1 == count2
            case (.failed(_), .failed(_)):
                return true
            default:
                return false
            }
        }
    }
    
    init() {
        print("HealthKitManager: Initializing...")
        
        // Check if HealthKit is available
        if !HKHealthStore.isHealthDataAvailable() {
            print("HealthKit not available on this device")
            authorizationStatus = .notAvailable
            return
        }
        
        // Initialize the store
        healthStore = HKHealthStore()
        
        // Initialize types - ONLY the basic types, not correlation
        initializeHealthKitTypes()
        
        // Check permission status
        checkPermissionStatus()
    }
    
    private func initializeHealthKitTypes() {
        // Initialize ONLY the individual quantity types
        bloodPressureSystolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)
        bloodPressureDiastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
        heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
    }
    
    // Check permissions for individual types
    func checkPermissionStatus() {
        guard let healthStore = healthStore else {
            authorizationStatus = .notAvailable
            return
        }
        
        // Check each type individually
        if let systolicType = bloodPressureSystolicType {
            hasSystolicPermission = healthStore.authorizationStatus(for: systolicType) == .sharingAuthorized
        }
        
        if let diastolicType = bloodPressureDiastolicType {
            hasDiastolicPermission = healthStore.authorizationStatus(for: diastolicType) == .sharingAuthorized
        }
        
        if let heartRateType = heartRateType {
            hasHeartRatePermission = healthStore.authorizationStatus(for: heartRateType) == .sharingAuthorized
        }
        
        // Update overall status
        updateAuthorizationStatus()
    }
    
    private func updateAuthorizationStatus() {
        // Check if types are available
        if bloodPressureSystolicType == nil ||
           bloodPressureDiastolicType == nil {
            authorizationStatus = .notAvailable
            return
        }
        
        let basicPermissions = [hasSystolicPermission, hasDiastolicPermission]
        
        if !basicPermissions.contains(true) {
            // No permissions granted - check if they've been determined
            if let systolicType = bloodPressureSystolicType,
               healthStore?.authorizationStatus(for: systolicType) == .notDetermined {
                authorizationStatus = .notDetermined
            } else {
                authorizationStatus = .denied
            }
        } else if basicPermissions.allSatisfy({ $0 }) {
            // All BP permissions granted
            authorizationStatus = .fullAccess
        } else {
            // Some but not all permissions granted
            authorizationStatus = .partialAccess
        }
        
        print("HealthKitManager: Updated authorization status to \(authorizationStatus)")
    }
    
    // Request authorization - ONLY for individual types, never correlation
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        guard let healthStore = healthStore else {
            completion?(false)
            return
        }
        
        isRequestingPermission = true
        
        // Initialize sets for read/write permissions
        var typesToShare: Set<HKSampleType> = []
        var typesToRead: Set<HKObjectType> = []
        
        // IMPORTANT: Only add individual types, NOT correlation type
        if let systolicType = bloodPressureSystolicType {
            typesToShare.insert(systolicType)
            typesToRead.insert(systolicType)
        }
        
        if let diastolicType = bloodPressureDiastolicType {
            typesToShare.insert(diastolicType)
            typesToRead.insert(diastolicType)
        }
        
        if let heartRateType = heartRateType {
            typesToShare.insert(heartRateType)
            typesToRead.insert(heartRateType)
        }
        
        // Request authorization
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Authorization error: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.isRequestingPermission = false
                
                // Re-check permissions
                self.checkPermissionStatus()
                
                // Report success if any permissions were granted
                let anyAccess = self.authorizationStatus == .fullAccess ||
                                self.authorizationStatus == .partialAccess
                completion?(anyAccess)
            }
        }
    }
    
    // Prepare for sync
    func prepareSync(_ readings: [BloodPressureReading]) {
        // Re-check permissions
        checkPermissionStatus()
        
        // If no permissions at all, need to request
        if authorizationStatus == .denied || authorizationStatus == .notDetermined {
            requestAuthorization { [weak self] success in
                guard let self = self, success else { return }
                self.prepareSync(readings)
            }
            return
        }
        
        // If we don't have permission for at least systolic or diastolic, can't sync
        if !hasSystolicPermission && !hasDiastolicPermission {
            DispatchQueue.main.async {
                self.syncStatus = .failed("No blood pressure permissions")
            }
            return
        }
        
        // Continue with sync preparation
        DispatchQueue.main.async {
            self.syncStatus = .checking
            self.existingReadingsCount = 0
            self.readingsToSyncCount = readings.count
            self.duplicateReadingsCount = 0
            self.showingSyncModal = true
        }
    }
    
    // Execute the sync with individual readings or correlation based on permissions
    func executeSync(_ readings: [BloodPressureReading]) {
        syncStatus = .syncing
        showingSyncModal = false
        
        guard let healthStore = healthStore else {
            syncStatus = .failed("HealthKit not available")
            return
        }
        
        // Track our progress
        var successCount = 0
        var failedCount = 0
        let group = DispatchGroup()
        
        for reading in readings {
            group.enter()
            
            // Try to save with correlation if available, otherwise fall back to individual readings
            saveReading(reading, healthStore: healthStore) { success, error in
                if success {
                    successCount += 1
                } else {
                    failedCount += 1
                    if let error = error {
                        print("Error saving reading: \(error.localizedDescription)")
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if failedCount == 0 {
                self.syncStatus = .completed(successCount)
            } else if successCount > 0 {
                self.syncStatus = .completed(successCount)
            } else {
                self.syncStatus = .failed("Failed to sync readings")
            }
        }
    }
    
    // Save reading with appropriate strategy based on permissions
    private func saveReading(_ reading: BloodPressureReading,
                           healthStore: HKHealthStore,
                           completion: @escaping (Bool, Error?) -> Void) {
        
        // Get combined date
        let combinedDate = createCombinedDate(from: reading)
        guard let date = combinedDate else {
            completion(false, nil)
            return
        }
        
        // If we have permission for both systolic and diastolic, try to use correlation
        if hasSystolicPermission && hasDiastolicPermission {
            saveBPWithCorrelation(reading, date: date, healthStore: healthStore) { success, error in
                if success {
                    // If correlation succeeds, also try to save heart rate
                    if self.hasHeartRatePermission, let heartRateType = self.heartRateType {
                        self.saveHeartRate(reading, date: date, heartRateType: heartRateType,
                                          healthStore: healthStore) { _, _ in
                            // Return success even if heart rate fails
                            completion(true, nil)
                        }
                    } else {
                        completion(true, nil)
                    }
                } else {
                    // If correlation fails, try individual readings as fallback
                    self.saveIndividualReadings(reading, date: date, healthStore: healthStore, completion: completion)
                }
            }
        } else {
            // Otherwise just save individual readings
            saveIndividualReadings(reading, date: date, healthStore: healthStore, completion: completion)
        }
    }
    
    // Save BP as correlation
    private func saveBPWithCorrelation(_ reading: BloodPressureReading,
                                      date: Date,
                                      healthStore: HKHealthStore,
                                      completion: @escaping (Bool, Error?) -> Void) {
        
        guard let systolicType = bloodPressureSystolicType,
              let diastolicType = bloodPressureDiastolicType else {
            completion(false, nil)
            return
        }
        
        // Create samples
        let systolicValue = HKQuantity(unit: HKUnit.millimeterOfMercury(),
                                     doubleValue: Double(reading.systolic))
        let diastolicValue = HKQuantity(unit: HKUnit.millimeterOfMercury(),
                                      doubleValue: Double(reading.diastolic))
        
        let systolicSample = HKQuantitySample(
            type: systolicType,
            quantity: systolicValue,
            start: date,
            end: date
        )
        
        let diastolicSample = HKQuantitySample(
            type: diastolicType,
            quantity: diastolicValue,
            start: date,
            end: date
        )
        
        // Create the correlation type at runtime - don't store it as property
        if let correlationType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure) {
            // Create correlation with samples
            let objects: Set<HKSample> = [systolicSample, diastolicSample]
            
            let correlation = HKCorrelation(
                type: correlationType,
                start: date,
                end: date,
                objects: objects
            )
            
            // Try to save the correlation
            healthStore.save(correlation) { success, error in
                completion(success, error)
            }
        } else {
            // Correlation type not available, fallback to individual samples
            completion(false, nil)
        }
    }
    
    // Save readings as individual samples
    private func saveIndividualReadings(_ reading: BloodPressureReading,
                                       date: Date,
                                       healthStore: HKHealthStore,
                                       completion: @escaping (Bool, Error?) -> Void) {
        
        let group = DispatchGroup()
        var successCount = 0
        var typesAvailable = 0
        
        // Try systolic
        if hasSystolicPermission, let systolicType = bloodPressureSystolicType {
            typesAvailable += 1
            group.enter()
            
            let systolicValue = HKQuantity(unit: HKUnit.millimeterOfMercury(),
                                         doubleValue: Double(reading.systolic))
            let systolicSample = HKQuantitySample(
                type: systolicType,
                quantity: systolicValue,
                start: date,
                end: date
            )
            
            healthStore.save(systolicSample) { success, _ in
                if success { successCount += 1 }
                group.leave()
            }
        }
        
        // Try diastolic
        if hasDiastolicPermission, let diastolicType = bloodPressureDiastolicType {
            typesAvailable += 1
            group.enter()
            
            let diastolicValue = HKQuantity(unit: HKUnit.millimeterOfMercury(),
                                          doubleValue: Double(reading.diastolic))
            let diastolicSample = HKQuantitySample(
                type: diastolicType,
                quantity: diastolicValue,
                start: date,
                end: date
            )
            
            healthStore.save(diastolicSample) { success, _ in
                if success { successCount += 1 }
                group.leave()
            }
        }
        
        // Try heart rate
        if hasHeartRatePermission, let heartRateType = heartRateType {
            typesAvailable += 1
            group.enter()
            
            saveHeartRate(reading, date: date, heartRateType: heartRateType, healthStore: healthStore) { success, _ in
                if success { successCount += 1 }
                group.leave()
            }
        }
        
        // Complete when all operations are done
        group.notify(queue: .main) {
            let success = successCount > 0
            completion(success, nil)
        }
    }
    
    // Helper to save heart rate
    private func saveHeartRate(_ reading: BloodPressureReading,
                              date: Date,
                              heartRateType: HKQuantityType,
                              healthStore: HKHealthStore,
                              completion: @escaping (Bool, Error?) -> Void) {
        
        let heartRateValue = HKQuantity(
            unit: HKUnit.count().unitDivided(by: HKUnit.minute()),
            doubleValue: Double(reading.heartRate)
        )
        
        let heartRateSample = HKQuantitySample(
            type: heartRateType,
            quantity: heartRateValue,
            start: date,
            end: date
        )
        
        healthStore.save(heartRateSample, withCompletion: completion)
    }
    
    // Helper to create date from reading
    private func createCombinedDate(from reading: BloodPressureReading) -> Date? {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let timeDate = dateFormatter.date(from: reading.time) else {
            return nil
        }
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: reading.date)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined)
    }
}
