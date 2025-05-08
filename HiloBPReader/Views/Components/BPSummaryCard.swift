import SwiftUI

struct BPSummaryCard: View {
    let stats: BPStats
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("BP Overview")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(Date().formatted(.dateTime.month().day()))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                // Systolic reading
                ValueDisplay(
                    value: stats.systolicMean,
                    title: "Systolic",
                    unit: "mmHg",
                    warningThreshold: 130,
                    dangerThreshold: 140
                )
                
                // Diastolic reading
                ValueDisplay(
                    value: stats.diastolicMean,
                    title: "Diastolic",
                    unit: "mmHg",
                    warningThreshold: 80,
                    dangerThreshold: 90
                )
                
                // Heart rate - now using white/neutral color
                ValueDisplay(
                    value: stats.heartRateMean,
                    title: "Heart Rate",
                    unit: "bpm",
                    warningThreshold: 90,
                    dangerThreshold: 100,
                    tintColor: .white,
                    useColorScale: false
                )
            }
            
            // Classification badge
            BPClassificationBadge(
                systolic: stats.systolicMean,
                diastolic: stats.diastolicMean
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondaryBackground)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

struct ValueDisplay: View {
    let value: Int
    let title: String
    let unit: String
    let warningThreshold: Int
    let dangerThreshold: Int
    var tintColor: Color = .blue
    var useColorScale: Bool = true
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(value)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(useColorScale ? valueColor : tintColor)
                .contentTransition(.numericText())
                .animation(.spring, value: value)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var valueColor: Color {
        if value <= 0 {
            return .gray // For zero or empty values
        } else if title == "Diastolic" {
            // Diastolic thresholds
            if value >= 90 {
                return .red
            } else if value >= 85 {
                return .orange
            } else if value >= 80 {
                return .yellow
            } else {
                return .green
            }
        } else if title == "Systolic" {
            // Systolic thresholds
            if value >= dangerThreshold {
                return .red
            } else if value >= warningThreshold {
                return .orange
            } else if value >= warningThreshold - 10 {
                return .yellow
            } else {
                return .green
            }
        } else {
            // Default for other values like heart rate
            if value >= dangerThreshold {
                return .red
            } else if value >= warningThreshold {
                return .orange
            } else {
                return tintColor
            }
        }
    }
}
