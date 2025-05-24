import SwiftUI

struct ReadingCard: View {
    let reading: BloodPressureReading
    
    @State private var isExpanded = false
    @State private var showPulse = false
    
    private var classification: BPClassification {
        BPClassificationService.shared.classify(
            systolic: reading.systolic,
            diastolic: reading.diastolic
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            cardHeader
            
            // Values section
            valuesSection
                .padding(.top, 16)
            
            // Footer with date and classification
            cardFooter
                .padding(.top, 16)
        }
        .padding(16)
        .frame(width: 160, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [Color.tertiaryBackground, Color.quaternaryBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.glassBorder, lineWidth: 1)
                )
        )
        .overlay(
            // Animated accent border
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [classification.color.opacity(0.6), classification.color.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .opacity(showPulse ? 0.8 : 0)
                .scaleEffect(showPulse ? 1.02 : 1)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showPulse)
        )
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        .shadow(color: classification.color.opacity(0.1), radius: 16, x: 0, y: 8)
        .scaleEffect(isExpanded ? 1.05 : 1)
        .animation(.spring(response: 0.3), value: isExpanded)
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
        .onAppear {
            if classification == .hypertensionStage2 || classification == .crisis {
                showPulse = true
            }
        }
    }
    
    private var cardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(reading.time)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                if reading.readingType != .normal && reading.readingType != .initialization {
                    readingTypeBadge
                }
            }
            
            Spacer()
            
            // Heart rate indicator
            heartRateView
        }
    }
    
    private var valuesSection: some View {
        VStack(spacing: 12) {
            // Systolic
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(reading.systolic)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.systolicGradient)
                    .contentTransition(.numericText())
                
                Text("SYS")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .offset(y: -6)
            }
            
            // Visual separator
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.clear, Color.glassBorder, Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // Diastolic
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(reading.diastolic)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.diastolicGradient)
                    .contentTransition(.numericText())
                
                Text("DIA")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .offset(y: -6)
            }
        }
    }
    
    private var cardFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Classification badge
            HStack(spacing: 6) {
                Circle()
                    .fill(classification.color)
                    .frame(width: 6, height: 6)
                
                Text(classification.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(classification.color)
            }
            
            // Date
            Text(formattedDate)
                .font(.system(size: 10))
                .foregroundColor(.tertiaryText)
        }
    }
    
    private var heartRateView: some View {
        VStack(spacing: 2) {
            Image(systemName: "heart.fill")
                .font(.system(size: 12))
                .foregroundColor(.heartRateColor)
                .symbolEffect(.pulse, value: showPulse)
            
            Text("\(reading.heartRate)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.heartRateColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.heartRateColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var readingTypeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: readingTypeIcon)
                .font(.system(size: 8))
            
            Text(readingTypeText)
                .font(.system(size: 9))
        }
        .foregroundColor(readingTypeColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(readingTypeColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(readingTypeColor.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Helper Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: reading.date)
    }
    
    private var readingTypeIcon: String {
        switch reading.readingType {
        case .cuffMeasurement: return "rectangle.fill"
        case .onDemandPhone: return "phone.fill"
        default: return ""
        }
    }
    
    private var readingTypeText: String {
        switch reading.readingType {
        case .cuffMeasurement: return "Cuff"
        case .onDemandPhone: return "Phone"
        default: return ""
        }
    }
    
    private var readingTypeColor: Color {
        switch reading.readingType {
        case .cuffMeasurement: return .primaryAccent
        case .onDemandPhone: return .secondaryAccent
        default: return .secondaryText
        }
    }
}

// MARK: - Horizontal Reading Card for lists

struct HorizontalReadingCard: View {
    let reading: BloodPressureReading
    
    @State private var isPressed = false
    
    private var classification: BPClassification {
        BPClassificationService.shared.classify(
            systolic: reading.systolic,
            diastolic: reading.diastolic
        )
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Time and type
            VStack(alignment: .leading, spacing: 4) {
                Text(reading.time)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                if reading.readingType != .normal && reading.readingType != .initialization {
                    HStack(spacing: 4) {
                        Image(systemName: readingTypeIcon)
                            .font(.system(size: 10))
                        Text(readingTypeText)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(readingTypeColor)
                }
                
                // Classification
                HStack(spacing: 4) {
                    Circle()
                        .fill(classification.color)
                        .frame(width: 6, height: 6)
                    Text(classification.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(classification.color)
                }
            }
            .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            // BP Values
            HStack(spacing: 20) {
                // Systolic
                VStack(spacing: 2) {
                    Text("\(reading.systolic)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.systolicGradient)
                    Text("SYS")
                        .font(.system(size: 10))
                        .foregroundColor(.secondaryText)
                }
                
                // Separator
                Text("/")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.tertiaryText)
                
                // Diastolic
                VStack(spacing: 2) {
                    Text("\(reading.diastolic)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.diastolicGradient)
                    Text("DIA")
                        .font(.system(size: 10))
                        .foregroundColor(.secondaryText)
                }
                
                // Heart rate
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.heartRateColor)
                        Text("\(reading.heartRate)")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primaryText)
                    }
                    Text("BPM")
                        .font(.system(size: 10))
                        .foregroundColor(.secondaryText)
                }
                .padding(.leading, 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.glassBorder, lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(classification.color.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: {}
    }
    
    private var readingTypeIcon: String {
        switch reading.readingType {
        case .cuffMeasurement: return "rectangle.fill"
        case .onDemandPhone: return "phone.fill"
        default: return ""
        }
    }
    
    private var readingTypeText: String {
        switch reading.readingType {
        case .cuffMeasurement: return "Cuff"
        case .onDemandPhone: return "Phone"
        default: return ""
        }
    }
    
    private var readingTypeColor: Color {
        switch reading.readingType {
        case .cuffMeasurement: return .primaryAccent
        case .onDemandPhone: return .secondaryAccent
        default: return .secondaryText
        }
    }
}
