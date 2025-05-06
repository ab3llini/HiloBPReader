import SwiftUI

struct ReadingRowView: View {
    let reading: BloodPressureReading
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(reading.formattedDateTime)
                    .font(.subheadline)
                
                HStack(spacing: 15) {
                    Label("\(reading.systolic)", systemImage: "arrow.up")
                        .foregroundColor(systolicColor)
                    
                    Label("\(reading.diastolic)", systemImage: "arrow.down")
                        .foregroundColor(diastolicColor)
                    
                    Label("\(reading.heartRate)", systemImage: "heart.fill")
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            if reading.readingType != .normal {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .opacity(0.7)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var systolicColor: Color {
        if reading.systolic >= 140 {
            return .red
        } else if reading.systolic >= 130 {
            return .orange
        }
        return .green
    }
    
    private var diastolicColor: Color {
        if reading.diastolic >= 90 {
            return .red
        } else if reading.diastolic >= 80 {
            return .orange
        }
        return .green
    }
}
