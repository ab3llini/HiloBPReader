import SwiftUI

struct ReadingCard: View {
    let reading: BloodPressureReading
    
    // Get the classification from the central service
    private var classification: BPClassification {
        BPClassificationService.shared.classify(
            systolic: reading.systolic,
            diastolic: reading.diastolic
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Time and heart rate on top row
            HStack {
                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Heart rate moved to top right
                HStack(spacing: 2) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                    Text("\(reading.heartRate)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            // Systolic value - horizontal layout
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(reading.systolic)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(systolicColor)
                Text("SYS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Diastolic value - horizontal layout
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(reading.diastolic)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(diastolicColor)
                Text("DIA")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Add the classification badge - NEW
            HStack {
                Circle()
                    .fill(classification.color)
                    .frame(width: 8, height: 8)
                Text(classification.rawValue)
                    .font(.caption)
                    .foregroundColor(classification.color)
            }
            
            // Date and reading type indicator
            HStack {
                // Date
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Reading type indicator with different icons based on type
                readingTypeIcon
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondaryBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .frame(width: 160)
    }
    
    private var formattedTime: String {
        return reading.time
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: reading.date)
    }
    
    private var readingTypeIcon: some View {
        Group {
            switch reading.readingType {
            case .initialization:
                Image(systemName: "target.fill")
                    .foregroundColor(.orange)
            case .cuffMeasurement:
                Image(systemName: "rectangle.fill")
                    .foregroundColor(.blue)
            case .onDemandPhone:
                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
            case .normal:
                EmptyView()
            }
        }
        .font(.caption)
    }
    
    // Now using the service
    private var systolicColor: Color {
        BPClassificationService.shared.systolicColor(reading.systolic)
    }
    
    // Now using the service
    private var diastolicColor: Color {
        BPClassificationService.shared.diastolicColor(reading.diastolic)
    }
}
