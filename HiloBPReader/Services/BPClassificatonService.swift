import SwiftUI

// Enum to represent BP classification categories
enum BPClassification: String, Codable, Identifiable {
    case normal = "Normal"
    case elevated = "Elevated"
    case hypertensionStage1 = "Hypertension Stage 1"
    case hypertensionStage2 = "Hypertension Stage 2"
    case crisis = "Hypertensive Crisis"
    
    var id: String { rawValue }
    
    // For searching
    var searchTerms: [String] {
        switch self {
        case .normal:
            return ["normal", "healthy", "good"]
        case .elevated:
            return ["elevated", "borderline", "high normal"]
        case .hypertensionStage1:
            return ["hypertension stage 1", "mild hypertension", "stage 1", "moderate"]
        case .hypertensionStage2:
            return ["hypertension stage 2", "stage 2", "severe", "high"]
        case .crisis:
            return ["crisis", "emergency", "critical", "dangerous", "very high", "severe"]
        }
    }
    
    // Associated color for this classification
    var color: Color {
        switch self {
        case .normal: return .green
        case .elevated: return .yellow
        case .hypertensionStage1: return .orange
        case .hypertensionStage2: return .red
        case .crisis: return Color(red: 0.8, green: 0, blue: 0)
        }
    }
    
    // Provide medical advice appropriate for each category
    var medicalAdvice: String {
        switch self {
        case .normal:
            return "Your blood pressure is in the normal range. Continue with healthy lifestyle habits."
        case .elevated:
            return "Your blood pressure is slightly elevated. Consider lifestyle changes and monitor regularly."
        case .hypertensionStage1:
            return "You have Stage 1 Hypertension. Consult with your healthcare provider and consider lifestyle changes."
        case .hypertensionStage2:
            return "You have Stage 2 Hypertension. Consult with your healthcare provider immediately for treatment options."
        case .crisis:
            return "MEDICAL EMERGENCY: Seek immediate medical attention if readings persist at this level or if you experience symptoms."
        }
    }
}

// Service class for BP classification logic
class BPClassificationService {
    
    static let shared = BPClassificationService()
    
    private init() {}
    
    // Classify a single reading
    func classify(systolic: Int, diastolic: Int) -> BPClassification {
        if systolic >= 180 || diastolic >= 120 {
            return .crisis
        } else if systolic >= 140 || diastolic >= 90 {
            return .hypertensionStage2
        } else if systolic >= 130 || diastolic >= 80 {
            return .hypertensionStage1
        } else if systolic >= 120 && diastolic < 80 {
            return .elevated
        } else {
            return .normal
        }
    }
    
    // Get color for systolic value
    func systolicColor(_ value: Int) -> Color {
        if value >= 160 {
            return .red
        } else if value >= 140 {
            return .orange
        } else if value >= 130 {
            return .yellow
        } else if value >= 120 {
            return .yellow
        } else {
            return .green
        }
    }
    
    // Get color for diastolic value
    func diastolicColor(_ value: Int) -> Color {
        if value >= 100 {
            return .red
        } else if value >= 90 {
            return .orange
        } else if value >= 80 {
            return .yellow
        } else {
            return .green
        }
    }
    
    // Get color for heart rate - simplified for example
    func heartRateColor(_ value: Int) -> Color {
        if value >= 100 {
            return .red
        } else if value >= 90 {
            return .orange
        } else if value <= 50 {
            return .blue
        } else {
            return .green
        }
    }
    
    // Extra method to check if a search term matches any BP classification
    func matchesClassification(searchTerm: String) -> BPClassification? {
        let lowercaseTerm = searchTerm.lowercased()
        
        for classification in [BPClassification.normal, .elevated, .hypertensionStage1, .hypertensionStage2, .crisis] {
            if classification.rawValue.lowercased().contains(lowercaseTerm) ||
               classification.searchTerms.contains(where: { $0.contains(lowercaseTerm) }) {
                return classification
            }
        }
        
        return nil
    }
}
