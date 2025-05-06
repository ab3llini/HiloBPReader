import SwiftUI

struct ValueGauge: View {
    let value: Int
    let title: String
    let range: ClosedRange<Int>
    let warningThreshold: Int
    let dangerThreshold: Int
    let unit: String
    var tintColor: Color = .blue
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(value)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
                .contentTransition(.numericText())
                .animation(.spring, value: value)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Circular gauge
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        valueColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring, value: value)
            }
            .frame(width: 50, height: 50)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var progress: Double {
        let min = Double(range.lowerBound)
        let max = Double(range.upperBound)
        let current = Double(value)
        return (current - min) / (max - min)
    }
    
    private var valueColor: Color {
        if value >= dangerThreshold {
            return .red
        } else if value >= warningThreshold {
            return .orange
        } else {
            return tintColor
        }
    }
}
