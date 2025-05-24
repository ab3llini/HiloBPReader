import SwiftUI

struct ActionButton: View {
    let title: String
    let icon: String
    var style: ButtonStyle = .primary
    var isLoading: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var showRipple = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case danger
        
        var gradient: LinearGradient {
            switch self {
            case .primary:
                return LinearGradient(
                    colors: [Color.primaryAccent, Color.primaryAccent.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .secondary:
                return LinearGradient(
                    colors: [Color.secondaryAccent, Color.secondaryAccent.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .danger:
                return LinearGradient(
                    colors: [Color.dangerAccent, Color.dangerAccent.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        
        var baseColor: Color {
            switch self {
            case .primary: return .primaryAccent
            case .secondary: return .secondaryAccent
            case .danger: return .dangerAccent
            }
        }
    }
    
    var body: some View {
        Button(action: {
            if !isLoading {
                // Haptic feedback
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                
                // Trigger ripple effect
                withAnimation(.easeOut(duration: 0.3)) {
                    showRipple = true
                }
                
                // Reset ripple
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showRipple = false
                }
                
                action()
            }
        }) {
            ZStack {
                // Background with gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(style.gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style.baseColor.opacity(0.3), lineWidth: 1)
                    )
                
                // Ripple effect
                if showRipple {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .scaleEffect(showRipple ? 3 : 0)
                        .opacity(showRipple ? 0 : 1)
                        .animation(.easeOut(duration: 0.5), value: showRipple)
                }
                
                // Content
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(isPressed ? 180 : 0))
                            .animation(.spring(response: 0.3), value: isPressed)
                    }
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .tracking(0.5)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .opacity(isLoading ? 0.7 : 1)
            }
            .frame(height: 56)
            .scaleEffect(isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .disabled(isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: {}
        .shadow(color: style.baseColor.opacity(0.3), radius: 16, x: 0, y: 8)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Alternative Minimal Button Style

struct MinimalActionButton: View {
    let title: String
    let icon: String
    var color: Color = .primaryAccent
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .tracking(0.3)
            }
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(isHovering ? 0.15 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isHovering ? 1.05 : 1)
            .animation(.spring(response: 0.3), value: isHovering)
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Icon Button

struct IconActionButton: View {
    let icon: String
    var size: CGFloat = 44
    var color: Color = .primaryAccent
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(color)
                    .scaleEffect(isPressed ? 0.8 : 1)
                    .animation(.spring(response: 0.3), value: isPressed)
            }
            .frame(width: size, height: size)
        }
        .scaleEffect(isPressed ? 0.9 : 1)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: {}
    }
}
