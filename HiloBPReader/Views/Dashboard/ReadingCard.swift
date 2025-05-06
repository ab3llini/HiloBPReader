import SwiftUI

struct ReadingCard: View {
    let reading: BloodPressureReading
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Time and type indicator
            HStack {
                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                
                if reading.readingType != .normal {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.8))
                }
            }
            
            // BP and HR values
            HStack(alignment: .bottom, spacing: 16) {
                // Systolic
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(reading.systolic)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(systolicColor)
                    Text("SYS")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Diastolic
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(reading.diastolic)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(diastolicColor)
                    Text("DIA")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Heart rate
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                        Text("\(reading.heartRate)")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text("BPM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Date
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondaryBackground)
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
    
    private var systolicColor: Color {
        if reading.systolic >= 140 {
            return .red
        } else if reading.systolic >= 130 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var diastolicColor: Color {
        if reading.diastolic >= 90 {
            return .red
        } else if reading.diastolic >= 80 {
            return .orange
        } else {
            return .green
        }
    }
}
