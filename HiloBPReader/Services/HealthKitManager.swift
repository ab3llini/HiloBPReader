import Foundation
import HealthKit
import SwiftUI

class HealthKitManager: ObservableObject {
    
    // HealthKit store - may be nil if HealthKit is not available
    private var healthStore: HKHealthStore?
    
    // Only initialize basic types, NOT correlation type
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
    
    // UserDefaults key for storing permission status
    private let permissionStatusKey = "HealthKitPermissionStatus"
    
    enum AuthorizationStatus: String, Equatable {
        case unknown = "unknown"            // We don't know yet
        case notAvailable = "notAvailable"  // HealthKit not available on device
        case notDetermined = "notDetermined" // Permission not yet requested
        case authorized = "authorized"       // Permission granted
        case denied = "denied"               // Permission denied
    }
    
    enum SyncStatus: Equatable {
        case idle
        case checking
        case syncing
        case completed(Int)
        case failed(Error?)
        
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
                // Consider all errors equal for comparison purposes
                return true
            default:
                return false
            }
        }
    }
    
    init() {
        print("HealthKitManager: Initializing...")
        
        // First load saved status if available
        loadSavedStatus()
        
        // Check if HealthKit is available
        if !HKHealthStore.isHealthDataAvailable() {
            print("HealthKitManager: HealthKit not available on this device")
            authorizationStatus = .notAvailable
            saveStatus(.notAvailable)
            return
        }
        
        // Only initialize if not denied
        if authorizationStatus != .denied {
            initializeBasicHealthKit()
        }
    }
    
    // Load the saved permission status
    private func loadSavedStatus() {
        if let savedStatusString = UserDefaults.standard.string(forKey: permissionStatusKey),
           let savedStatus = AuthorizationStatus(rawValue: savedStatusString) {
            print("HealthKitManager: Found saved status: \(savedStatus)")
            authorizationStatus = savedStatus
        } else {
            print("HealthKitManager: No saved status found, defaulting to unknown")
            authorizationStatus = .unknown
        }
    }
    
    // Save status to UserDefaults
    private func saveStatus(_ status: AuthorizationStatus) {
        UserDefaults.standard.set(status.rawValue, forKey: permissionStatusKey)
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        print("HealthKitManager: Saved status as \(status)")
    }
    
    // Initialize just the basic HealthKit types (not correlation)
    private func initializeBasicHealthKit() {
        print("HealthKitManager: Initializing basic HealthKit...")
        
        // Initialize the store
        healthStore = HKHealthStore()
        
        // Initialize ONLY basic quantity types, NOT correlation type
        bloodPressureSystolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)
        bloodPressureDiastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
        heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
        
        // Check the actual status of these basic types
        checkBasicPermissionStatus()
    }
    
    // Check permission status for basic types only
    func checkBasicPermissionStatus() {
        guard let healthStore = healthStore,
              let systolicType = bloodPressureSystolicType,
              let diastolicType = bloodPressureDiastolicType else {
            print("HealthKitManager: Store or basic types not available")
            authorizationStatus = .notAvailable
            saveStatus(.notAvailable)
            return
        }
        
        print("HealthKitManager: Checking basic permission status...")
        
        // Only check basic quantity types, never the correlation type
        let systolicStatus = healthStore.authorizationStatus(for: systolicType)
        let diastolicStatus = healthStore.authorizationStatus(for: diastolicType)
        
        if systolicStatus == .sharingAuthorized && diastolicStatus == .sharingAuthorized {
            print("HealthKitManager: Status is authorized")
            authorizationStatus = .authorized
            saveStatus(.authorized)
        } else if systolicStatus == .sharingDenied || diastolicStatus == .sharingDenied {
            print("HealthKitManager: Status is denied")
            authorizationStatus = .denied
            saveStatus(.denied)
        } else {
            print("HealthKitManager: Status is not determined")
            authorizationStatus = .notDetermined
            saveStatus(.notDetermined)
        }
    }
    
    // Request authorization
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        guard let healthStore = healthStore,
              let systolicType = bloodPressureSystolicType,
              let diastolicType = bloodPressureDiastolicType,
              let heartRateType = heartRateType else {
            print("HealthKitManager: Cannot request auth - store or types not available")
            authorizationStatus = .notAvailable
            saveStatus(.notAvailable)
            completion?(false)
            return
        }
        
        DispatchQueue.main.async {
            self.isRequestingPermission = true
        }
        
        print("HealthKitManager: Requesting authorization...")
        
        // Get correlation type only when requesting (don't store it)
        let bloodPressureCorrelationType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!
        
        // Types to share (write)
        let typesToShare: Set<HKSampleType> = [
            systolicType,
            diastolicType,
            heartRateType
        ]
        
        // Types to read - include correlation type
        let typesToRead: Set<HKObjectType> = [
            systolicType,
            diastolicType,
            heartRateType,
            bloodPressureCorrelationType
        ]
        
        // Request authorization
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            guard let self = self else { return }
            
            print("HealthKitManager: Authorization result: \(success), error: \(String(describing: error))")
            
            // Wait a moment for the system to process the permission
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isRequestingPermission = false
                
                // Check the status again to be sure
                self.checkBasicPermissionStatus()
                
                // Call the completion handler with the current status
                completion?(self.authorizationStatus == .authorized)
            }
        }
    }
    
    // Prepare for sync
    func prepareSync(_ readings: [BloodPressureReading]) {
        print("HealthKitManager: Preparing sync. Current status: \(authorizationStatus)")
        
        // Skip if not authorized
        guard authorizationStatus == .authorized else {
            // If not determined, try to request authorization
            if authorizationStatus == .notDetermined {
                requestAuthorization { success in
                    if success {
                        self.prepareSync(readings)
                    }
                }
            } else if authorizationStatus == .denied {
                print("HealthKitManager: Cannot sync - permission denied")
            }
            return
        }
        
        DispatchQueue.main.async {
            self.syncStatus = .checking
            // Default values
            self.existingReadingsCount = 0
            self.readingsToSyncCount = readings.count
            self.duplicateReadingsCount = 0
            self.showingSyncModal = true
        }
        
        print("HealthKitManager: Ready to sync \(readings.count) readings")
    }
    
    // Execute the sync
    func executeSync(_ readings: [BloodPressureReading]) {
        // Skip if not authorized
        guard authorizationStatus == .authorized,
              let healthStore = healthStore,
              let systolicType = bloodPressureSystolicType,
              let diastolicType = bloodPressureDiastolicType,
              let heartRateType = heartRateType else {
            print("HealthKitManager: Cannot execute sync - not authorized or types missing")
            DispatchQueue.main.async {
                self.syncStatus = .failed(nil)
            }
            return
        }
        
        // Get correlation type only when we know we have permission
        guard let bloodPressureCorrelationType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure) else {
            print("HealthKitManager: Cannot execute sync - correlation type not available")
            DispatchQueue.main.async {
                self.syncStatus = .failed(nil)
            }
            return
        }
        
        DispatchQueue.main.async {
            self.syncStatus = .syncing
            self.showingSyncModal = false
        }
        
        print("HealthKitManager: Starting sync of \(readings.count) readings")
        
        // Simply sync all readings (skipping duplicate detection for now)
        let group = DispatchGroup()
        var successCount = 0
        var failedCount = 0
        
        for reading in readings {
            group.enter()
            
            // Save the reading
            saveReading(
                reading: reading,
                systolicType: systolicType,
                diastolicType: diastolicType,
                heartRateType: heartRateType,
                correlationType: bloodPressureCorrelationType,
                healthStore: healthStore
            ) { success, error in
                if success {
                    successCount += 1
                } else {
                    failedCount += 1
                    print("HealthKitManager: Failed to save reading: \(String(describing: error))")
                }
                group.leave()
            }
        }
        
        // When all are done
        group.notify(queue: .main) {
            if failedCount == 0 {
                print("HealthKitManager: Sync completed successfully with \(successCount) readings")
                self.syncStatus = .completed(successCount)
            } else {
                print("HealthKitManager: Sync failed with \(failedCount) errors")
                self.syncStatus = .failed(nil)
            }
        }
    }
    
    // Save a single reading - pass all types explicitly
    private func saveReading(
        reading: BloodPressureReading,
        systolicType: HKQuantityType,
        diastolicType: HKQuantityType,
        heartRateType: HKQuantityType,
        correlationType: HKCorrelationType,
        healthStore: HKHealthStore,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        // Create date components for precise time
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let timeDate = dateFormatter.date(from: reading.time) else {
            print("HealthKitManager: Invalid time format")
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
            print("HealthKitManager: Failed to create combined date")
            completion(false, nil)
            return
        }
        
        // Create the correlation
        let systolicValue = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: Double(reading.systolic))
        let diastolicValue = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: Double(reading.diastolic))
        
        let systolicSample = HKQuantitySample(
            type: systolicType,
            quantity: systolicValue,
            start: combinedDate,
            end: combinedDate
        )
        
        let diastolicSample = HKQuantitySample(
            type: diastolicType,
            quantity: diastolicValue,
            start: combinedDate,
            end: combinedDate
        )
        
        let objects: Set<HKSample> = [systolicSample, diastolicSample]
        
        let correlation = HKCorrelation(type: correlationType, start: combinedDate, end: combinedDate, objects: objects)
        
        // Save the correlation
        healthStore.save(correlation) { (success, error) in
            if success {
                // Now save heart rate separately
                let heartRateValue = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: Double(reading.heartRate))
                let heartRateSample = HKQuantitySample(
                    type: heartRateType,
                    quantity: heartRateValue,
                    start: combinedDate,
                    end: combinedDate
                )
                
                healthStore.save(heartRateSample, withCompletion: completion)
            } else {
                print("HealthKitManager: Failed to save correlation: \(String(describing: error))")
                completion(success, error)
            }
        }
    }
    
    // For debugging - reset the stored permission status
    func resetSavedPermissions() {
        UserDefaults.standard.removeObject(forKey: permissionStatusKey)
        print("HealthKitManager: Reset saved permissions")
        
        // Reset to unknown
        DispatchQueue.main.async {
            self.authorizationStatus = .unknown
        }
        
        // Re-check if we can
        if authorizationStatus != .denied {
            initializeBasicHealthKit()
        }
    }
}
