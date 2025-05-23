import SwiftUI

// Extension for consistent app colors
extension Color {
    // Primary brand colors
    static let primaryAccent = Color("AccentColor")
    static let secondaryAccent = Color.blue
    
    // Background hierarchy - FIXED: Uncommented and using proper fallbacks
//    static let mainBackground = Color("MainBackground")
//    static let secondaryBackground = Color("SecondaryBackground")
//    static let cardBackground = Color("CardBackground")
    
    // Reading colors
    static let systolicColor = Color.red
    static let diastolicColor = Color.blue
    static let heartRateColor = Color.pink
    
    // Classification colors - using semantic colors with proper fallbacks
    static let normalBP = Color.green
    static let elevatedBP = Color.yellow
    static let highBP1 = Color.orange
    static let highBP2 = Color.red
    static let crisisBP = Color(red: 0.8, green: 0, blue: 0)
    
    // Time of day colors
    static let morningColor = Color.orange
    static let eveningColor = Color.indigo
}
