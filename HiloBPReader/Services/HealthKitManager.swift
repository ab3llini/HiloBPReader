import Foundation
import HealthKit
import SwiftUI

@MainActor
class HealthKitManager: ObservableObject {
    
    // MARK: - Core Properties
    private let healthStore = HKHealthStore()
    
    // Quantity types (lazily initialized)
    private lazy var bpTypes: BPQuantityTypes = {
        BPQuantityTypes(
            systolic: HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
            diastolic: HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic),
            heartRate: HKQuantityType.quantityType(forIdentifier: .heartRate)
        )
    }()
    
    // MARK: - Published State (simplified)
    @Published var authStatus: AuthStatus = .checking
    @Published var syncState: SyncState = .idle
    @Published var showingSyncModal = false
    
    // MARK: - Computed Properties
    var canSync: Bool {
        authStatus.hasAnyBPPermission && HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Types
    enum AuthStatus: Equatable {
        case checking
        case unavailable
        case denied
        case partial(permissions: Set<BPPermission>)
        case full
        
        var hasAnyBPPermission: Bool {
            switch self {
            case .partial(let perms): return !perms.intersection([.systolic, .diastolic]).isEmpty
            case .full: return true
            default: return false
            }
        }
    }
    
    enum SyncState {
        case idle
        case preparing
        case syncing(progress: Double)
        case completed(count: Int)
        case failed(error: HealthKitError)
    }
    
    enum BPPermission: CaseIterable, Equatable {
        case systolic, diastolic, heartRate
    }
    
    enum HealthKitError: LocalizedError {
        case notAvailable
        case permissionDenied
        case syncFailed(underlying: Error)
        
        var errorDescription: String? {
            switch self {
            case .notAvailable: return "HealthKit is not available on this device"
            case .permissionDenied: return "Health permissions are required"
            case .syncFailed(let error): return "Sync failed: \(error.localizedDescription)"
            }
        }
    }
    
    init() {
        Task { await checkInitialPermissions() }
    }
    
    // MARK: - Permission Management
    func requestPermissions() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            authStatus = .unavailable
            return false
        }
        
        let typesToRequest = bpTypes.allValidTypes
        guard !typesToRequest.isEmpty else { return false }
        
        do {
            try await healthStore.requestAuthorization(
                toShare: Set(typesToRequest),
                read: Set(typesToRequest)
            )
            
            await checkInitialPermissions()
            return authStatus.hasAnyBPPermission
            
        } catch {
            authStatus = .denied
            return false
        }
    }
    
    private func checkInitialPermissions() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authStatus = .unavailable
            return
        }
        
        let permissions = await bpTypes.checkPermissions(healthStore: healthStore)
        
        authStatus = switch permissions.count {
        case 0: .denied
        case BPPermission.allCases.count: .full
        default: .partial(permissions: permissions)
        }
    }
    
    // MARK: - Sync Operations
    func prepareSync(readings: [BloodPressureReading]) async {
        guard canSync else {
            syncState = .failed(error: .permissionDenied)
            return
        }
        
        syncState = .preparing
        
        // Check for duplicates efficiently
        let duplicateCount = await countDuplicates(readings: readings)
        let uniqueReadings = readings.count - duplicateCount
        
        // Show modal if we have readings to sync
        if uniqueReadings > 0 {
            showingSyncModal = true
        } else {
            syncState = .completed(count: 0)
        }
    }
    
    func executeSync(readings: [BloodPressureReading]) async {
        await performSync(readings: readings)
    }
    
    private func performSync(readings: [BloodPressureReading]) async {
        syncState = .syncing(progress: 0)
        showingSyncModal = false
        
        do {
            let syncer = HealthDataSyncer(
                healthStore: healthStore,
                bpTypes: bpTypes,
                permissions: getCurrentPermissions()
            )
            
            let syncedCount = try await syncer.syncReadings(readings) { progress in
                await MainActor.run {
                    self.syncState = .syncing(progress: progress)
                }
            }
            
            syncState = .completed(count: syncedCount)
            
        } catch {
            syncState = .failed(error: .syncFailed(underlying: error))
        }
    }
    
    // MARK: - Helper Methods
    private func getCurrentPermissions() -> Set<BPPermission> {
        switch authStatus {
        case .partial(let permissions): return permissions
        case .full: return Set(BPPermission.allCases)
        default: return []
        }
    }
    
    private func countDuplicates(readings: [BloodPressureReading]) async -> Int {
        // Simplified duplicate detection - in production you'd query HealthKit
        // This is a placeholder that assumes you have some local tracking
        return 0
    }
}

// MARK: - Supporting Types
private struct BPQuantityTypes {
    let systolic: HKQuantityType?
    let diastolic: HKQuantityType?
    let heartRate: HKQuantityType?
    
    var allValidTypes: [HKQuantityType] {
        [systolic, diastolic, heartRate].compactMap { $0 }
    }
    
    func checkPermissions(healthStore: HKHealthStore) async -> Set<HealthKitManager.BPPermission> {
        var permissions: Set<HealthKitManager.BPPermission> = []
        
        if let systolic = systolic,
           healthStore.authorizationStatus(for: systolic) == .sharingAuthorized {
            permissions.insert(.systolic)
        }
        
        if let diastolic = diastolic,
           healthStore.authorizationStatus(for: diastolic) == .sharingAuthorized {
            permissions.insert(.diastolic)
        }
        
        if let heartRate = heartRate,
           healthStore.authorizationStatus(for: heartRate) == .sharingAuthorized {
            permissions.insert(.heartRate)
        }
        
        return permissions
    }
}

// MARK: - Sync Engine
private struct HealthDataSyncer {
    let healthStore: HKHealthStore
    let bpTypes: BPQuantityTypes
    let permissions: Set<HealthKitManager.BPPermission>
    
    func syncReadings(_ readings: [BloodPressureReading],
                     progressCallback: @escaping (Double) async -> Void) async throws -> Int {
        
        var syncedCount = 0
        let total = readings.count
        
        for (index, reading) in readings.enumerated() {
            do {
                let wasSynced = try await syncSingleReading(reading)
                if wasSynced { syncedCount += 1 }
                
                // Update progress
                let progress = Double(index + 1) / Double(total)
                await progressCallback(progress)
                
            } catch {
                // Log error but continue with other readings
                print("Failed to sync reading: \(error)")
            }
        }
        
        return syncedCount
    }
    
    private func syncSingleReading(_ reading: BloodPressureReading) async throws -> Bool {
        guard let date = combineDateTime(reading: reading) else { return false }
        
        var samples: [HKQuantitySample] = []
        
        // Create samples based on available permissions
        if permissions.contains(.systolic), let systolicType = bpTypes.systolic {
            let sample = HKQuantitySample(
                type: systolicType,
                quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: Double(reading.systolic)),
                start: date,
                end: date
            )
            samples.append(sample)
        }
        
        if permissions.contains(.diastolic), let diastolicType = bpTypes.diastolic {
            let sample = HKQuantitySample(
                type: diastolicType,
                quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: Double(reading.diastolic)),
                start: date,
                end: date
            )
            samples.append(sample)
        }
        
        if permissions.contains(.heartRate), let heartRateType = bpTypes.heartRate {
            let sample = HKQuantitySample(
                type: heartRateType,
                quantity: HKQuantity(unit: .hertz(), doubleValue: Double(reading.heartRate) / 60.0),
                start: date,
                end: date
            )
            samples.append(sample)
        }
        
        // Save samples
        try await withCheckedThrowingContinuation { continuation in
            healthStore.save(samples) { success, error in
                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: error ?? HealthKitManager.HealthKitError.syncFailed(underlying: NSError()))
                }
            }
        }
        
        return !samples.isEmpty
    }
    
    private func combineDateTime(reading: BloodPressureReading) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let timeDate = formatter.date(from: reading.time) else { return nil }
        
        let calendar = Calendar.current
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
