import SwiftUI

struct SyncHealthModal: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    let readings: [BloodPressureReading]
    @Binding var isPresented: Bool
    
    @State private var animateContent = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    modalHeader
                    
                    // Main content
                    mainContent
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    
                    Spacer()
                    
                    // Action buttons
                    actionButtons
                }
                .padding(24)
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animateContent = true
                }
            }
        }
    }
    
    private var modalHeader: some View {
        HStack {
            Text("Apple Health Sync")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Button(action: { isPresented = false }) {
                ZStack {
                    Circle()
                        .fill(Color.quaternaryBackground)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : -20)
        .animation(.spring(response: 0.5).delay(0.1), value: animateContent)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch healthKitManager.syncState {
        case .idle:
            idleStateView
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.8)
                .animation(.spring(response: 0.6).delay(0.2), value: animateContent)
            
        case .preparing:
            preparingStateView
            
        case .syncing(let progress):
            syncingStateView(progress: progress)
            
        case .completed(let count):
            completedStateView(count: count)
            
        case .failed(let error):
            failedStateView(error: error)
        }
    }
    
    private var idleStateView: some View {
        VStack(spacing: 32) {
            // Animated icon
            ZStack {
                // Gradient background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.dangerAccent.opacity(0.2),
                                Color.dangerAccent.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dangerAccent, Color.dangerAccent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse.wholeSymbol)
            }
            
            // Info text
            VStack(spacing: 16) {
                Text("Ready to Sync")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text("Your blood pressure readings will be added to Apple Health, making them available to other health apps and your healthcare providers.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondaryText)
            }
            
            // Stats cards
            HStack(spacing: 16) {
                StatCard(
                    icon: "waveform.path.ecg",
                    value: "\(readings.count)",
                    label: "Readings",
                    color: .primaryAccent
                )
                
                StatCard(
                    icon: permissionIcon,
                    value: permissionStatusShort,
                    label: "Access",
                    color: permissionColor
                )
            }
        }
    }
    
    private var preparingStateView: some View {
        VStack(spacing: 24) {
            LoadingIndicator(style: .preparing)
            
            Text("Preparing sync...")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            Text("Checking for duplicates")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
    }
    
    private func syncingStateView(progress: Double) -> some View {
        VStack(spacing: 24) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.glassBorder, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.primaryAccent, Color.secondaryAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text("Syncing")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            
            Text("Adding readings to Apple Health...")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
    }
    
    private func completedStateView(count: Int) -> some View {
        VStack(spacing: 24) {
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.successAccent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.successAccent)
                    .symbolEffect(.bounce)
            }
            
            VStack(spacing: 8) {
                Text("Sync Complete!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("\(count) readings added to Apple Health")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            
            // Success stats
            HStack(spacing: 16) {
                SuccessStatPill(
                    icon: "heart.fill",
                    label: "Blood Pressure",
                    isActive: true
                )
                
                SuccessStatPill(
                    icon: "waveform",
                    label: "Heart Rate",
                    isActive: healthKitManager.authStatus == .full
                )
            }
        }
    }
    
    private func failedStateView(error: HealthKitManager.HealthKitError) -> some View {
        VStack(spacing: 24) {
            // Error icon
            ZStack {
                Circle()
                    .fill(Color.dangerAccent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.dangerAccent)
                    .symbolEffect(.bounce)
            }
            
            VStack(spacing: 8) {
                Text("Sync Failed")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondaryText)
            }
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        switch healthKitManager.syncState {
        case .idle:
            HStack(spacing: 16) {
                Button(action: { isPresented = false }) {
                    Text("Cancel")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primaryAccent, lineWidth: 2)
                        )
                }
                
                ActionButton(
                    title: "Sync Now",
                    icon: "arrow.triangle.2.circlepath",
                    style: .primary
                ) {
                    Task {
                        await healthKitManager.executeSync(readings: readings)
                    }
                }
                .disabled(!healthKitManager.canSync || readings.isEmpty)
            }
            
        case .completed(_), .failed(_):
            ActionButton(
                title: "Done",
                icon: "checkmark",
                style: .primary
            ) {
                isPresented = false
            }
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Helper Properties
    
    private var permissionIcon: String {
        switch healthKitManager.authStatus {
        case .full: return "checkmark.shield.fill"
        case .partial: return "exclamationmark.shield.fill"
        default: return "xmark.shield.fill"
        }
    }
    
    private var permissionColor: Color {
        switch healthKitManager.authStatus {
        case .full: return .successAccent
        case .partial: return .warningAccent
        default: return .dangerAccent
        }
    }
    
    private var permissionStatusShort: String {
        switch healthKitManager.authStatus {
        case .full: return "Full"
        case .partial: return "Partial"
        case .denied: return "Denied"
        case .unavailable: return "N/A"
        default: return "..."
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct SuccessStatPill: View {
    let icon: String
    let label: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(isActive ? .successAccent : .secondaryText)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isActive ? .primaryText : .secondaryText)
            
            if isActive {
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.successAccent)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isActive ? Color.successAccent.opacity(0.1) : Color.quaternaryBackground)
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.successAccent.opacity(0.3) : Color.glassBorder, lineWidth: 1)
                )
        )
    }
}

struct LoadingIndicator: View {
    enum Style {
        case preparing, syncing
    }
    
    let style: Style
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.primaryAccent.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .scaleEffect(isAnimating ? 1 : 0.5)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever()
                        .delay(Double(index) * 0.5),
                        value: isAnimating
                    )
            }
        }
        .frame(width: 80, height: 80)
        .onAppear {
            isAnimating = true
        }
    }
}
