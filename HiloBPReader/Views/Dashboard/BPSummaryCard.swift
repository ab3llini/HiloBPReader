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
                // Systolic reading with gauge
                ValueGauge(
                    value: stats.systolicMean,
                    title: "Systolic",
                    range: 90...180,
                    warningThreshold: 130,
                    dangerThreshold: 140,
                    unit: "mmHg"
                )
                
                // Diastolic reading with gauge
                ValueGauge(
                    value: stats.diastolicMean,
                    title: "Diastolic",
                    range: 50...120,
                    warningThreshold: 80,
                    dangerThreshold: 90,
                    unit: "mmHg"
                )
                
                // Heart rate
                ValueGauge(
                    value: stats.heartRateMean,
                    title: "Heart Rate",
                    range: 40...100,
                    warningThreshold: 90,
                    dangerThreshold: 100,
                    unit: "bpm",
                    tintColor: .red
                )
            }
            
            BPClassificationBadge(
                systolic: stats.systolicMean,
                diastolic: stats.diastolicMean
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.cardBackground, Color.cardBackground.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}
