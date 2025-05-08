import SwiftUI

struct BPSummaryCard: View {
    let stats: BPStats
    let readings: [BloodPressureReading] // Added to access the readings
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("BP Overview")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                
                // Period indication instead of today's date
                Text("Last 30 Days")
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                // Systolic reading with trend
                ValueDisplayWithTrend(
                    value: stats.systolicMean,
                    title: "Systolic",
                    unit: "mmHg",
                    warningThreshold: 130,
                    dangerThreshold: 140,
                    trend: calculateTrend(for: "systolic")
                )
                
                // Diastolic reading with trend
                ValueDisplayWithTrend(
                    value: stats.diastolicMean,
                    title: "Diastolic",
                    unit: "mmHg",
                    warningThreshold: 80,
                    dangerThreshold: 90,
                    trend: calculateTrend(for: "diastolic")
                )
                
                // Heart rate with trend
                ValueDisplayWithTrend(
                    value: stats.heartRateMean,
                    title: "Heart Rate",
                    unit: "bpm",
                    warningThreshold: 90,
                    dangerThreshold: 100,
                    tintColor: .white,
                    useColorScale: false,
                    trend: calculateTrend(for: "heartrate")
                )
            }
            
            // Range indicators
            HStack(spacing: 20) {
                RangeIndicator(
                    title: "Systolic Range",
                    range: calculateRange(for: "systolic")
                )
                
                RangeIndicator(
                    title: "Diastolic Range",
                    range: calculateRange(for: "diastolic")
                )
                
                // Readings count
                ReadingsInfo(count: readings.count)
            }
            .padding(.top, 4)
            
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
    
    // Calculate trend: returns (direction, percentage change)
    private func calculateTrend(for type: String) -> (direction: TrendDirection, change: Double) {
        guard !readings.isEmpty else {
            return (.stable, 0)
        }
        
        // Sort readings by date
        let sortedReadings = readings.sorted(by: { $0.date < $1.date })
        
        // Split readings into two halves (first 15 days vs last 15 days)
        let midpoint = max(1, sortedReadings.count / 2)
        let firstHalf = Array(sortedReadings.prefix(midpoint))
        let secondHalf = Array(sortedReadings.suffix(sortedReadings.count - midpoint))
        
        // Calculate averages for both periods
        let firstAvg: Double
        let secondAvg: Double
        
        switch type {
        case "systolic":
            firstAvg = firstHalf.map { Double($0.systolic) }.reduce(0, +) / Double(firstHalf.count)
            secondAvg = secondHalf.map { Double($0.systolic) }.reduce(0, +) / Double(secondHalf.count)
        case "diastolic":
            firstAvg = firstHalf.map { Double($0.diastolic) }.reduce(0, +) / Double(firstHalf.count)
            secondAvg = secondHalf.map { Double($0.diastolic) }.reduce(0, +) / Double(secondHalf.count)
        case "heartrate":
            firstAvg = firstHalf.map { Double($0.heartRate) }.reduce(0, +) / Double(firstHalf.count)
            secondAvg = secondHalf.map { Double($0.heartRate) }.reduce(0, +) / Double(secondHalf.count)
        default:
            return (.stable, 0)
        }
        
        // Calculate percentage change
        let change = (secondAvg - firstAvg) / firstAvg * 100
        
        // Determine direction
        let direction: TrendDirection
        if abs(change) < 2 {
            direction = .stable
        } else if change > 0 {
            direction = .increasing
        } else {
            direction = .decreasing
        }
        
        return (direction, abs(change))
    }
    
    // Calculate min-max range
    private func calculateRange(for type: String) -> (min: Int, max: Int) {
        guard !readings.isEmpty else {
            return (0, 0)
        }
        
        // Get last 30 days readings
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let recentReadings = readings.filter { $0.date >= thirtyDaysAgo }
        
        switch type {
        case "systolic":
            let values = recentReadings.map { $0.systolic }
            return (values.min() ?? 0, values.max() ?? 0)
        case "diastolic":
            let values = recentReadings.map { $0.diastolic }
            return (values.min() ?? 0, values.max() ?? 0)
        case "heartrate":
            let values = recentReadings.map { $0.heartRate }
            return (values.min() ?? 0, values.max() ?? 0)
        default:
            return (0, 0)
        }
    }
}

// Trend direction enum
enum TrendDirection {
    case increasing
    case decreasing
    case stable
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up"
        case .decreasing: return "arrow.down"
        case .stable: return "arrow.forward"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing: return .red
        case .decreasing: return .green
        case .stable: return .gray
        }
    }
}

// Enhanced value display with trend indicator
struct ValueDisplayWithTrend: View {
    let value: Int
    let title: String
    let unit: String
    let warningThreshold: Int
    let dangerThreshold: Int
    var tintColor: Color = .blue
    var useColorScale: Bool = true
    var trend: (direction: TrendDirection, change: Double)
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(useColorScale ? valueColor : tintColor)
                    .contentTransition(.numericText())
                    .animation(.spring, value: value)
                
                // Trend indicator
                Image(systemName: trend.direction.icon)
                    .foregroundColor(trend.direction.color)
                    .font(.caption)
                    .opacity(trend.change > 0 ? 1 : 0) // Hide if no change
            }
            
            HStack {
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if trend.change > 0 {
                    Text("\(Int(trend.change))%")
                        .font(.caption)
                        .foregroundColor(trend.direction.color)
                }
            }
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

// Range indicator component
struct RangeIndicator: View {
    let title: String
    let range: (min: Int, max: Int)
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(range.min) - \(range.max)")
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Readings info component
struct ReadingsInfo: View {
    let count: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text("Readings")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(count)")
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
