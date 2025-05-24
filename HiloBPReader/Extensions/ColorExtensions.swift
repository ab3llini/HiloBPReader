import SwiftUI

// Extension for consistent app colors with modern design system
extension Color {
    // MARK: - Base Colors
    static let primaryBackground = Color(hex: "0A0E1A") // Deep blue-black
    static let secondaryBackground = Color(hex: "141925") // Slightly lighter
    static let tertiaryBackground = Color(hex: "1C2333") // Card backgrounds
    static let quaternaryBackground = Color(hex: "242B3D") // Elevated elements
    
    // MARK: - Accent Colors
    static let primaryAccent = Color(hex: "4A9EFF") // Bright blue
    static let secondaryAccent = Color(hex: "00D4AA") // Teal
    static let dangerAccent = Color(hex: "FF6B6B") // Coral red
    static let warningAccent = Color(hex: "FFB84D") // Warm orange
    static let successAccent = Color(hex: "4ECDC4") // Mint
    
    // MARK: - Text Colors
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let tertiaryText = Color.white.opacity(0.5)
    
    // MARK: - Semantic Colors for BP
    static let systolicGradientStart = Color(hex: "FF6B6B")
    static let systolicGradientEnd = Color(hex: "FF8787")
    static let diastolicGradientStart = Color(hex: "4A9EFF")
    static let diastolicGradientEnd = Color(hex: "74B9FF")
    static let heartRateColor = Color(hex: "FF6B9D")
    
    // MARK: - BP Classification Colors (refined)
    static let bpNormal = Color(hex: "4ECDC4")
    static let bpElevated = Color(hex: "95E1D3")
    static let bpStage1 = Color(hex: "FFB84D")
    static let bpStage2 = Color(hex: "FF6B6B")
    static let bpCrisis = Color(hex: "C44569")
    
    // MARK: - Utility
    static let glassBorder = Color.white.opacity(0.1)
    static let glassBackground = Color.white.opacity(0.05)
    
    // Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static let systolicGradient = LinearGradient(
        colors: [Color.systolicGradientStart, Color.systolicGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let diastolicGradient = LinearGradient(
        colors: [Color.diastolicGradientStart, Color.diastolicGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color.tertiaryBackground, Color.secondaryBackground],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let glassGradient = LinearGradient(
        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Shadow Extensions
extension View {
    func glassMorphism() -> some View {
        self
            .background(.ultraThinMaterial)
            .background(LinearGradient.glassGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.glassBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    func cardShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
            .shadow(color: .primaryAccent.opacity(0.1), radius: 20, x: 0, y: 0)
    }
}
