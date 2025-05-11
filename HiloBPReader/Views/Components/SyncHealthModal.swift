import SwiftUI

struct SyncHealthModal: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    let readings: [BloodPressureReading]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header image
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                    .padding(.top, 20)
                
                // Title
                Text("Health Sync Summary")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Stats and info
                VStack(spacing: 16) {
                    syncInfoRow(
                        label: "Readings to sync",
                        value: "\(healthKitManager.readingsToSyncCount)",
                        icon: "arrow.up.to.line.circle.fill",
                        color: .green
                    )
                    
                    syncInfoRow(
                        label: "Duplicates to skip",
                        value: "\(healthKitManager.duplicateReadingsCount)",
                        icon: "rectangle.slash.fill",
                        color: .orange
                    )
                    
                    syncInfoRow(
                        label: "Existing in Health",
                        value: "\(healthKitManager.existingReadingsCount)",
                        icon: "heart.text.square.fill",
                        color: .blue
                    )
                }
                .padding()
                .background(Color.secondaryBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Info text
                Text("Duplicates are detected based on date, time, and values to avoid double entries in Apple Health.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        healthKitManager.executeSync(readings)
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.heart")
                            Text("Sync Now")
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(healthKitManager.readingsToSyncCount == 0)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
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
    
    private func syncInfoRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(label)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .padding(.vertical, 6)
    }
}
