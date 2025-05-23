import SwiftUI

struct SyncHealthModal: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    let readings: [BloodPressureReading]
    @Binding var isPresented: Bool
    
    @State private var isPreparingSync = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header image
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                    .padding(.top, 20)
                
                // Title
                Text("Sync to Apple Health")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Sync status based on current state
                syncStatusView
                
                // Info text
                Text("Your blood pressure readings will be added to Apple Health, where you can view them alongside other health data.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
            .padding()
            .navigationBarTitle("", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var syncStatusView: some View {
        VStack(spacing: 16) {
            switch healthKitManager.syncState {
            case .idle:
                // Show reading count and permissions
                VStack(spacing: 12) {
                    syncInfoCard(
                        title: "Readings to Sync",
                        value: "\(readings.count)",
                        icon: "waveform.path.ecg",
                        color: .blue
                    )
                    
                    permissionStatusCard
                }
                
            case .preparing:
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Preparing sync...")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                
            case .syncing(let progress):
                VStack {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)
                    Text("Syncing... \(Int(progress * 100))%")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                
            case .completed(let count):
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("Synced \(count) readings")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
            case .failed(let error):
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text("Sync Failed")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var permissionStatusCard: some View {
        HStack {
            Image(systemName: permissionIcon)
                .foregroundColor(permissionColor)
            
            VStack(alignment: .leading) {
                Text("Health Permissions")
                    .font(.headline)
                Text(permissionStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(permissionColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var permissionIcon: String {
        switch healthKitManager.authStatus {
        case .full: return "checkmark.circle.fill"
        case .partial: return "exclamationmark.circle.fill"
        default: return "xmark.circle.fill"
        }
    }
    
    private var permissionColor: Color {
        switch healthKitManager.authStatus {
        case .full: return .green
        case .partial: return .orange
        default: return .red
        }
    }
    
    private var permissionStatusText: String {
        switch healthKitManager.authStatus {
        case .full: return "Full access granted"
        case .partial: return "Partial access - some data may not sync"
        case .denied: return "Access denied"
        case .unavailable: return "HealthKit not available"
        default: return "Checking permissions..."
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        switch healthKitManager.syncState {
        case .idle:
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Sync Now") {
                    Task {
                        await healthKitManager.executeSync(readings: readings)
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!healthKitManager.canSync || readings.isEmpty)
            }
            
        case .completed(_), .failed(_):
            Button("Done") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            
        default:
            // Show nothing during sync/preparation
            EmptyView()
        }
    }
    
    private func syncInfoCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(value)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
