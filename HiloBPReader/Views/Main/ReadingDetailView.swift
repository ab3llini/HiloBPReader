import SwiftUI

struct ReadingDetailView: View {
    let reading: BloodPressureReading
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Date and time header
                    VStack(spacing: 8) {
                        Text(formatDate(reading.date))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(reading.time)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // BP values with large displays
                    HStack(spacing: 20) {
                        // Systolic
                        VStack(spacing: 8) {
                            Text("Systolic")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(reading.systolic)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(systolicColor(reading.systolic))
                            
                            Text("mmHg")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondaryBackground)
                        )
                        
                        // Diastolic
                        VStack(spacing: 8) {
                            Text("Diastolic")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(reading.diastolic)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(diastolicColor(reading.diastolic))
                            
                            Text("mmHg")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondaryBackground)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Heart rate card
                    VStack(spacing: 8) {
                        Text("Heart Rate")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(reading.heartRate)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                            
                            Text("BPM")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        }
                        
                        // Heart rate classification
                        heartRateDescription
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondaryBackground)
                    )
                    .padding(.horizontal)
                    
                    // BP Classification
                    VStack(spacing: 16) {
                        Text("Blood Pressure Classification")
                            .font(.headline)
                        
                        BPClassificationBadge(
                            systolic: reading.systolic,
                            diastolic: reading.diastolic
                        )
                        
                        Text(bpClassificationDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondaryBackground)
                    )
                    .padding(.horizontal)
                    
                    // Reading type note
                    if reading.readingType != .normal {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Reading Type: \(readingTypeString(reading.readingType))")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color.mainBackground.ignoresSafeArea())
            .navigationTitle("Reading Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var heartRateDescription: some View {
        Group {
            if reading.heartRate < 60 {
                Text("Your heart rate is below the typical resting range")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            } else if reading.heartRate <= 100 {
                Text("Your heart rate is within normal range")
                    .font(.subheadline)
                    .foregroundColor(.green)
            } else {
                Text("Your heart rate is above the typical resting range")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .multilineTextAlignment(.center)
    }
    
    private var bpClassificationDescription: String {
        if reading.systolic >= 180 || reading.diastolic >= 120 {
            return "Hypertensive crisis: Consult your doctor immediately or seek emergency care."
        } else if reading.systolic >= 140 || reading.diastolic >= 90 {
            return "Stage 2 hypertension: Consult with your healthcare provider about treatment options."
        } else if reading.systolic >= 130 || reading.diastolic >= 80 {
            return "Stage 1 hypertension: Talk to your doctor about lifestyle changes and potential medications."
        } else if reading.systolic >= 120 && reading.diastolic < 80 {
            return "Elevated: Consider heart-healthy lifestyle changes to lower your blood pressure."
        } else {
            return "Normal: Maintain your healthy lifestyle to keep blood pressure in this range."
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func systolicColor(_ value: Int) -> Color {
        if value >= 140 {
            return .red
        } else if value >= 130 {
            return .orange
        } else if value >= 120 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func diastolicColor(_ value: Int) -> Color {
        if value >= 90 {
            return .red
        } else if value >= 80 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func readingTypeString(_ type: BloodPressureReading.ReadingType) -> String {
        switch type {
        case .normal:
            return "Standard Measurement"
        case .initialization:
            return "Initialization with Cuff"
        case .cuffMeasurement:
            return "Calibration Cuff Measurement"
        case .onDemandPhone:
            return "On-Demand Phone Measurement"
        }
    }
}
