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
            
            // Heart rate and date in a row
            HStack {
                // Heart rate
                HStack(spacing: 2) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                    Text("\(reading.heartRate)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Date
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
    
    private var systolicColor: Color {
        if reading.systolic >= 160 {
            return .red
        } else if reading.systolic >= 140 {
            return .orange
        } else if reading.systolic >= 130 {
            return .yellow
        } else if reading.systolic >= 100 {
            return .green
        } else {
            return .blue // Low BP is blue
        }
    }
    
    private var diastolicColor: Color {
        if reading.diastolic >= 100 {
            return .red
        } else if reading.diastolic >= 90 {
            return .orange
        } else if reading.diastolic >= 85 {
            return .yellow
        } else {
            return .green
        }
    }
}
