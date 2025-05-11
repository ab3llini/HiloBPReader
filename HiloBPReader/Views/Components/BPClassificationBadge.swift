import SwiftUI

struct BPClassificationBadge: View {
    let systolic: Int
    let diastolic: Int
    @State private var showingAdvice = false
    
    // Get classification from central service
    private var classification: BPClassification {
        BPClassificationService.shared.classify(
            systolic: systolic,
            diastolic: diastolic
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(classification.color)
                    .frame(width: 8)
                
                Text(classification.rawValue)
                    .font(.headline)
                    .foregroundColor(classification.color)
                
                Spacer()
                
                Button(action: {
                    showingAdvice = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(classification.color.opacity(0.2))
            .cornerRadius(8)
            
            // Expandable medical advice section
            if showingAdvice {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Medical Information")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAdvice = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    Text(classification.medicalAdvice)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if classification == .crisis {
                        Text("If you're experiencing symptoms such as severe headache, shortness of breath, nosebleeds, or severe anxiety, call emergency services or go to the nearest emergency room.")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                    
                    Text("This is general information and not medical advice. Always consult with your healthcare provider about your blood pressure readings.")
                        .font(.caption2)
                        .italic()
                        .padding(.top, 6)
                }
                .padding()
                .background(Color.secondaryBackground)
                .cornerRadius(8)
                .transition(.opacity)
                .padding(.top, 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingAdvice)
    }
}
