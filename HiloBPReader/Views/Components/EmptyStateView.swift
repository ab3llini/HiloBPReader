import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Animated icon container
            ZStack {
                // Background circles
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.primaryAccent.opacity(0.1),
                                Color.primaryAccent.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating ? 1.1 : 1)
                    .animation(
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.secondaryAccent.opacity(0.1),
                                Color.secondaryAccent.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(isAnimating ? 1 : 1.1)
                    .animation(
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true)
                        .delay(0.5),
                        value: isAnimating
                    )
                
                // Main icon
                Image(systemName: icon)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.primaryAccent, Color.secondaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating)
            }
            
            // Text content
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            
            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                MinimalActionButton(
                    title: actionTitle,
                    icon: "arrow.right",
                    color: .primaryAccent,
                    action: action
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    static var noReadings: EmptyStateView {
        EmptyStateView(
            icon: "waveform.path.ecg",
            title: "No Readings Yet",
            message: "Import your Hilo report to start tracking your blood pressure journey"
        )
    }
    
    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try adjusting your search terms or filters"
        )
    }
    
    static var noConnection: EmptyStateView {
        EmptyStateView(
            icon: "wifi.exclamationmark",
            title: "No Connection",
            message: "Check your internet connection and try again"
        )
    }
    
    static var syncComplete: EmptyStateView {
        EmptyStateView(
            icon: "checkmark.circle.fill",
            title: "All Synced!",
            message: "Your readings are up to date with Apple Health"
        )
    }
}
