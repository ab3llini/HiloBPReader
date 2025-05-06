import SwiftUI

extension Color {

    // Default dark mode colors if custom ones aren't set
    static func defaultColor(_ named: String) -> Color {
        Color(named, bundle: nil)
            .defaultColor()
    }
    
    func defaultColor() -> Color {
        let uiColor = UIColor(self)
        if uiColor.description == "nil" {
            // If the color does not exist, return a fallback
            switch self {
            case Color.mainBackground:
                return Color(UIColor.systemBackground)
            case Color.secondaryBackground:
                return Color(UIColor.secondarySystemBackground)
            case Color.cardBackground:
                return Color(UIColor.tertiarySystemBackground)
            default:
                return self
            }
        }
        return self
    }
}
