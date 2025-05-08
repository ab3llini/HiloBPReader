import SwiftUI

struct BPClassificationBadge: View {
    let systolic: Int
    let diastolic: Int
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(classificationColor)
                .frame(width: 8)
            
            Text(classificationText)
                .font(.headline)
                .foregroundColor(classificationColor)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(classificationColor.opacity(0.2))
        .cornerRadius(8)
    }
    
    private var classification: BPClassification {
        if systolic >= 180 || diastolic >= 120 {
            return .crisis
        } else if systolic >= 160 || diastolic >= 100 {
            return .hypertensionStage2
        } else if systolic >= 140 || diastolic >= 90 {
            return .hypertensionStage1
        } else if systolic >= 130 || diastolic >= 80 {
            return .elevated
        } else {
            return .normal
        }
    }
    
    private var classificationText: String {
        switch classification {
        case .normal: return "Normal"
        case .elevated: return "Elevated"
        case .hypertensionStage1: return "Hypertension Stage 1"
        case .hypertensionStage2: return "Hypertension Stage 2"
        case .crisis: return "Hypertensive Crisis"
        }
    }
    
    private var classificationColor: Color {
        switch classification {
        case .normal: return .green
        case .elevated: return .yellow
        case .hypertensionStage1: return .orange
        case .hypertensionStage2: return .red
        case .crisis: return .red
        }
    }
}

enum BPClassification {
    case normal
    case elevated
    case hypertensionStage1
    case hypertensionStage2
    case crisis
}
