import SwiftUI

struct ReadingCard: View {
    let reading: BloodPressureReading
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Time and type indicator
            HStack {
                Text(reading.time)
                    .font(.callout)
                    .fontWeight(.medium)
                
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(reading.systolic)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(systolicColor)
                    Text("SYS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Diastolic
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(reading.diastolic)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(diastolicColor)
                    Text("DIA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Heart rate
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                        Text("\(reading.heartRate)")
                            .font(.system(size: 22, weight: .bold))
                    }
                    Text("BPM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Date
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .frame(width: 180)
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
        } else if reading.systolic >= 120 {
            return .yellow
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
