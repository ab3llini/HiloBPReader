import SwiftUI

struct BPClassificationBadge: View {
    let systolic: Int
    let diastolic: Int
    @State private var showingAdvice = false
    @State private var animateGlow = false
    
    private var classification: BPClassification {
        BPClassificationService.shared.classify(
            systolic: systolic,
            diastolic: diastolic
        )
    }
    
    private var classificationColor: Color {
        switch classification {
        case .normal: return .bpNormal
        case .elevated: return .bpElevated
        case .hypertensionStage1: return .bpStage1
        case .hypertensionStage2: return .bpStage2
        case .crisis: return .bpCrisis
        }
    }
    
    private var shouldPulse: Bool {
        classification == .crisis || classification == .hypertensionStage2
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main badge
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showingAdvice.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Status indicator
                    ZStack {
                        Circle()
                            .fill(classificationColor)
                            .frame(width: 12, height: 12)
                        
                        if shouldPulse {
                            Circle()
                                .stroke(classificationColor, lineWidth: 2)
                                .frame(width: 20, height: 20)
                                .scaleEffect(animateGlow ? 1.5 : 1)
                                .opacity(animateGlow ? 0 : 0.8)
                                .animation(
                                    .easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false),
                                    value: animateGlow
                                )
                        }
                    }
                    
                    // Classification text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(classification.rawValue)
                            .font(.headline)
                            .foregroundColor(.primaryText)
                        
                        Text("\(systolic)/\(diastolic) mmHg")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Info button
                    Image(systemName: showingAdvice ? "info.circle.fill" : "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(showingAdvice ? classificationColor : .secondaryText)
                        .rotationEffect(.degrees(showingAdvice ? 180 : 0))
                        .animation(.spring(response: 0.3), value: showingAdvice)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(classificationColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(classificationColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            
            // Expandable advice section
            if showingAdvice {
                medicalAdviceView
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .onAppear {
            if shouldPulse {
                animateGlow = true
            }
        }
    }
    
    private var medicalAdviceView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [classificationColor, classificationColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Medical Information")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showingAdvice = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondaryText)
                }
            }
            
            // Classification-specific advice
            VStack(alignment: .leading, spacing: 12) {
                // Main advice
                Text(classification.medicalAdvice)
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Additional critical warning if needed
                if classification == .crisis {
                    criticalWarningView
                }
                
                // Recommendations
                recommendationsView
                
                // Disclaimer
                disclaimerView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.glassBorder, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        .padding(.top, 8)
    }
    
    private var criticalWarningView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(.dangerAccent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Immediate Action Required")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.dangerAccent)
                
                Text("If experiencing symptoms like severe headache, chest pain, shortness of breath, or vision changes, seek emergency care immediately.")
                    .font(.caption)
                    .foregroundColor(.primaryText)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.dangerAccent.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.dangerAccent.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var recommendationsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommendations")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            ForEach(recommendationsForClassification, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.successAccent)
                        .offset(y: 2)
                    
                    Text(recommendation)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
        }
    }
    
    private var disclaimerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(.tertiaryText)
            
            Text("This is general information only. Always consult with your healthcare provider about your blood pressure readings.")
                .font(.caption2)
                .foregroundColor(.tertiaryText)
                .italic()
        }
        .padding(.top, 8)
    }
    
    private var recommendationsForClassification: [String] {
        switch classification {
        case .normal:
            return [
                "Maintain a healthy lifestyle",
                "Regular exercise (150 min/week)",
                "Balanced diet with low sodium",
                "Annual check-ups"
            ]
        case .elevated:
            return [
                "Lifestyle modifications recommended",
                "Reduce sodium intake (<2,300mg/day)",
                "Increase physical activity",
                "Monitor BP regularly"
            ]
        case .hypertensionStage1:
            return [
                "Consult healthcare provider",
                "DASH diet consideration",
                "Weight management if needed",
                "Stress reduction techniques"
            ]
        case .hypertensionStage2:
            return [
                "Medical evaluation needed",
                "Medication may be required",
                "Lifestyle changes essential",
                "Regular monitoring crucial"
            ]
        case .crisis:
            return [
                "Seek immediate medical attention",
                "Do not delay treatment",
                "Follow emergency protocols",
                "Call emergency services if symptomatic"
            ]
        }
    }
}

// MARK: - Compact Badge Variant

struct CompactBPClassificationBadge: View {
    let classification: BPClassification
    
    private var classificationColor: Color {
        switch classification {
        case .normal: return .bpNormal
        case .elevated: return .bpElevated
        case .hypertensionStage1: return .bpStage1
        case .hypertensionStage2: return .bpStage2
        case .crisis: return .bpCrisis
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(classificationColor)
                .frame(width: 8, height: 8)
            
            Text(classification.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(classificationColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(classificationColor.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(classificationColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
