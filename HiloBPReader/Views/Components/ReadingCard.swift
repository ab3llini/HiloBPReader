import SwiftUI

struct ReadingCard: View {
    let reading: BloodPressureReading
    
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
            
            // Date and reading type indicator
            HStack {
                // Date
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Reading type indicator (if not normal)
                if reading.readingType != .normal {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.8))
                }
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
