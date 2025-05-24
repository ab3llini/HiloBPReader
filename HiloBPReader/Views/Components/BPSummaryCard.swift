import SwiftUI

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

struct BPSummaryCard: View {
    let stats: BPStats
    let readings: [BloodPressureReading]
    
    @State private var animateValues = false
    @State private var showDetailedStats = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card
            VStack(spacing: 20) {
                // Header
                cardHeader
                
                // Main metrics
                mainMetricsView
                    .padding(.top, 8)
                
                // Classification badge
                classificationView
                    .padding(.top, 12)
                
                // Trend indicators
                trendIndicatorsView
                    .padding(.top, 16)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.glassBorder, lineWidth: 1)
                    )
            )
            .cardShadow()
            
            // Quick stats pills
            quickStatsPills
                .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateValues = true
            }
        }
    }
    
    private var cardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("BP Overview")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .textCase(.uppercase)
                    .tracking(1.2)
                
                Text(dateRangeText)
                    .font(.footnote)
                    .foregroundColor(.tertiaryText)
            }
            
            Spacer()
            
            // Pulse animation indicator
            PulseIndicator()
        }
    }
    
    private var mainMetricsView: some View {
        HStack(spacing: 0) {
            // Systolic
            VStack(spacing: 8) {
                Text("SYS")
                    .font(.caption2)
                    .foregroundColor(.secondaryText)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(animateValues ? "\(stats.systolicMean)" : "—")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.systolicGradient)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: stats.systolicMean)
                
                TrendBadge(trend: calculateTrend(for: "systolic"))
            }
            .frame(maxWidth: .infinity)
            
            // Divider
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.tertiaryText)
                    .frame(width: 3, height: 3)
                Text("/")
                    .font(.title2)
                    .foregroundColor(.tertiaryText)
                Circle()
                    .fill(Color.tertiaryText)
                    .frame(width: 3, height: 3)
            }
            
            // Diastolic
            VStack(spacing: 8) {
                Text("DIA")
                    .font(.caption2)
                    .foregroundColor(.secondaryText)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(animateValues ? "\(stats.diastolicMean)" : "—")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.diastolicGradient)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: stats.diastolicMean)
                
                TrendBadge(trend: calculateTrend(for: "diastolic"))
            }
            .frame(maxWidth: .infinity)
            
            // Heart rate
            VStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.heartRateColor)
                    .symbolEffect(.pulse)
                
                Text(animateValues ? "\(stats.heartRateMean)" : "—")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryText)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: stats.heartRateMean)
                
                Text("BPM")
                    .font(.caption2)
                    .foregroundColor(.tertiaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.quaternaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.glassBorder, lineWidth: 0.5)
                    )
            )
        }
    }
    
    private var classificationView: some View {
        let classification = BPClassificationService.shared.classify(
            systolic: stats.systolicMean,
            diastolic: stats.diastolicMean
        )
        
        return HStack(spacing: 12) {
            Circle()
                .fill(classificationColor(classification))
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(classificationColor(classification))
                        .frame(width: 16, height: 16)
                        .opacity(0.3)
                        .scaleEffect(animateValues ? 1.5 : 1)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateValues)
                )
            
            Text(classification.rawValue)
                .font(.headline)
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Button(action: { showDetailedStats.toggle() }) {
                Image(systemName: "info.circle.fill")
                    .font(.body)
                    .foregroundColor(.tertiaryText)
                    .rotationEffect(.degrees(showDetailedStats ? 180 : 0))
                    .animation(.spring(response: 0.3), value: showDetailedStats)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(classificationColor(classification).opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(classificationColor(classification).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var trendIndicatorsView: some View {
        HStack(spacing: 12) {
            MetricPill(
                icon: "arrow.up.arrow.down",
                label: "Range",
                value: "\(calculateRange(for: "systolic").min)-\(calculateRange(for: "systolic").max)",
                color: .secondaryAccent
            )
            
            MetricPill(
                icon: "chart.line.uptrend.xyaxis",
                label: "Readings",
                value: "\(readings.count)",
                color: .primaryAccent
            )
            
            if readings.count > 30 {
                MetricPill(
                    icon: "checkmark.circle",
                    label: "Consistency",
                    value: "\(consistencyScore)%",
                    color: .successAccent
                )
            }
        }
    }
    
    private var quickStatsPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickStatPill(
                    label: "Morning Avg",
                    value: morningAverage,
                    icon: "sunrise.fill",
                    gradient: LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                QuickStatPill(
                    label: "Evening Avg",
                    value: eveningAverage,
                    icon: "sunset.fill",
                    gradient: LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                QuickStatPill(
                    label: "Variability",
                    value: "\(variabilityScore)%",
                    icon: "waveform.path.ecg",
                    gradient: LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func classificationColor(_ classification: BPClassification) -> Color {
        switch classification {
        case .normal: return .bpNormal
        case .elevated: return .bpElevated
        case .hypertensionStage1: return .bpStage1
        case .hypertensionStage2: return .bpStage2
        case .crisis: return .bpCrisis
        }
    }
    
    // MARK: - Computed Properties
    
    private var dateRangeText: String {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return "\(formatter.string(from: startDate)) → \(formatter.string(from: endDate))"
    }
    
    private var morningAverage: String {
        let morningReadings = readings.filter { reading in
            let hour = Calendar.current.component(.hour, from: reading.date)
            return hour >= 6 && hour < 12
        }
        
        guard !morningReadings.isEmpty else { return "—" }
        
        let avgSys = morningReadings.map { $0.systolic }.reduce(0, +) / morningReadings.count
        let avgDia = morningReadings.map { $0.diastolic }.reduce(0, +) / morningReadings.count
        
        return "\(avgSys)/\(avgDia)"
    }
    
    private var eveningAverage: String {
        let eveningReadings = readings.filter { reading in
            let hour = Calendar.current.component(.hour, from: reading.date)
            return hour >= 18 && hour < 24
        }
        
        guard !eveningReadings.isEmpty else { return "—" }
        
        let avgSys = eveningReadings.map { $0.systolic }.reduce(0, +) / eveningReadings.count
        let avgDia = eveningReadings.map { $0.diastolic }.reduce(0, +) / eveningReadings.count
        
        return "\(avgSys)/\(avgDia)"
    }
    
    private var consistencyScore: Int {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let daysWithReadings = Set(readings.filter { $0.date >= thirtyDaysAgo }.map {
            Calendar.current.startOfDay(for: $0.date)
        }).count
        
        return min(100, (daysWithReadings * 100) / 30)
    }
    
    private var variabilityScore: Int {
        guard readings.count > 1 else { return 0 }
        
        let systolicValues = readings.map { Double($0.systolic) }
        let mean = systolicValues.reduce(0, +) / Double(systolicValues.count)
        let variance = systolicValues.map { pow($0 - mean, 2) }.reduce(0, +) / Double(systolicValues.count)
        let stdDev = sqrt(variance)
        
        // Convert to percentage (lower is better)
        return max(0, min(100, Int(100 - (stdDev / mean * 100))))
    }
    
    // Keep existing helper methods
    private func calculateTrend(for type: String) -> (direction: TrendDirection, change: Double) {
        // ... existing implementation ...
        guard !readings.isEmpty else { return (.stable, 0) }
        let sortedReadings = readings.sorted(by: { $0.date < $1.date })
        guard sortedReadings.count >= 3 else { return (.stable, 0) }
        
        let calendar = Calendar.current
        let now = Date()
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now)!
        let fourWeeksAgo = calendar.date(byAdding: .day, value: -28, to: now)!
        
        let recentReadings = sortedReadings.filter { $0.date >= twoWeeksAgo && $0.date <= now }
        let previousReadings = sortedReadings.filter { $0.date >= fourWeeksAgo && $0.date < twoWeeksAgo }
        
        if recentReadings.isEmpty || previousReadings.isEmpty { return (.stable, 0) }
        
        let recentAvg: Double
        let previousAvg: Double
        
        switch type {
        case "systolic":
            recentAvg = recentReadings.map { Double($0.systolic) }.reduce(0, +) / Double(recentReadings.count)
            previousAvg = previousReadings.map { Double($0.systolic) }.reduce(0, +) / Double(previousReadings.count)
        case "diastolic":
            recentAvg = recentReadings.map { Double($0.diastolic) }.reduce(0, +) / Double(recentReadings.count)
            previousAvg = previousReadings.map { Double($0.diastolic) }.reduce(0, +) / Double(previousReadings.count)
        default:
            return (.stable, 0)
        }
        
        let change = previousAvg != 0 ? ((recentAvg - previousAvg) / previousAvg) * 100 : 0
        let significanceThreshold = 3.0
        
        let direction: TrendDirection = abs(change) < significanceThreshold ? .stable : (change > 0 ? .increasing : .decreasing)
        
        return (direction, abs(change))
    }
    
    private func calculateRange(for type: String) -> (min: Int, max: Int) {
        // ... existing implementation ...
        guard !readings.isEmpty else { return (0, 0) }
        
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let recentReadings = readings.filter { $0.date >= thirtyDaysAgo }
        
        switch type {
        case "systolic":
            let values = recentReadings.map { $0.systolic }
            return (values.min() ?? 0, values.max() ?? 0)
        default:
            return (0, 0)
        }
    }
}

// MARK: - Supporting Views

struct PulseIndicator: View {
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(Color.successAccent)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Color.successAccent, lineWidth: 2)
                    .scaleEffect(isPulsing ? 2 : 1)
                    .opacity(isPulsing ? 0 : 1)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: isPulsing)
            )
            .onAppear { isPulsing = true }
    }
}

struct TrendBadge: View {
    let trend: (direction: TrendDirection, change: Double)
    
    var body: some View {
        if trend.change > 0 {
            HStack(spacing: 4) {
                Image(systemName: trend.direction.icon)
                    .font(.caption2)
                Text("\(Int(trend.change))%")
                    .font(.caption2)
            }
            .foregroundColor(trendColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(trendColor.opacity(0.2))
            )
        }
    }
    
    private var trendColor: Color {
        switch trend.direction {
        case .increasing: return .warningAccent
        case .decreasing: return .successAccent
        case .stable: return .secondaryText
        }
    }
}

struct MetricPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.tertiaryText)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct QuickStatPill: View {
    let label: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(gradient)
                Spacer()
            }
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primaryText)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondaryText)
        }
        .frame(width: 120)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color.quaternaryBackground, Color.tertiaryBackground],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(gradient.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
