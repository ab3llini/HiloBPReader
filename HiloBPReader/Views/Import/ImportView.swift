import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    @State private var pdfURL: URL?
    @State private var isShowingDocumentPicker = false
    @State private var importStatus: ImportStatus = .idle
    @State private var importedReport: BloodPressureReport?
    @State private var duplicateCount = 0
    @State private var totalReadingsCount = 0
    
    // Added to track security-scoped resource access
    @State private var securityScopedAccessGranted = false
    
    // New states for validation
    @State private var hasValidationError = false
    @State private var validationErrors: [String] = []
    @State private var hasCheckedReadings = false
    @State private var hasCriticalReadings = false
    @State private var criticalReadingsCount = 0
    
    enum ImportStatus {
        case idle, processing, success, failure, validating
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status display
                    statusView
                    
                    // PDF preview if available
                    if let url = pdfURL, importStatus == .success {
                        PDFPreview(url: url)
                            .frame(height: 300)
                            .padding()
                    }
                    
                    // Validation errors - NEW
                    if hasValidationError {
                        validationErrorView
                    }
                    
                    // Critical readings warning - NEW
                    if hasCriticalReadings, let report = importedReport {
                        criticalReadingsView(report: report)
                    }
                    
                    // Import results
                    if let report = importedReport {
                        importSummaryView(report: report)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    actionButtons
                }
                .padding()
                .background(Color.mainBackground.ignoresSafeArea())
                .navigationTitle("Import Report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $isShowingDocumentPicker) {
                    PDFPickerView { url, securitySuccess in
                        pdfURL = url
                        securityScopedAccessGranted = securitySuccess
                        processImport(url: url)
                    }
                }
                .alert("Confirm Import", isPresented: $hasCriticalReadings) {
                    Button("Cancel", role: .cancel) { }
                    Button("Continue Import", role: .destructive) {
                        // Continue with import even with critical readings
                        hasCriticalReadings = false
                    }
                } message: {
                    Text("The report contains \(criticalReadingsCount) readings in the Hypertensive Crisis range (SYS ≥ 180 or DIA ≥ 120). Please confirm these are correct before importing.")
                }
                .onDisappear {
                    // Make sure we release security-scoped resource access when leaving the view
                    stopSecurityScopedAccess()
                }
            }
        }
    }
    
    // NEW - Validation Error View
    private var validationErrorView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("Validation Warnings")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Spacer()
            }
            
            ForEach(validationErrors, id: \.self) { error in
                Text("• \(error)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Please check your PDF to ensure the data is correct.")
                .font(.caption)
                .italic()
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // NEW - Critical Readings View
    private func criticalReadingsView(report: BloodPressureReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("Warning: Critical Blood Pressure Readings")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Spacer()
            }
            
            Text("This report contains \(criticalReadingsCount) readings in the Hypertensive Crisis range (≥180/120 mmHg).")
                .font(.callout)
            
            Text("Please verify these readings are correct before importing. If these readings are accurate and you have not already done so, please consult with a healthcare provider.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusView: some View {
        VStack(spacing: 15) {
            switch importStatus {
            case .idle:
                VStack(spacing: 20) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 70))
                        .foregroundColor(.accentColor)
                    
                    Text("Import Your Hilo Report")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select a Hilo blood pressure PDF report to import your readings.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 40)
                
            case .processing:
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Analyzing your report...")
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                
            case .validating:
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Validating data integrity...")
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                
            case .success:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Import successful!")
                        .fontWeight(.semibold)
                }
                
            case .failure:
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Failed to process report")
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        if importStatus == .idle {
            // Initial select button
            return Button {
                isShowingDocumentPicker = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Select PDF")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        } else if importStatus == .success {
            // After success, just provide a done button
            return Button {
                dataStore.setCurrentReport(importedReport)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Done")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        } else {
            // For failure or processing, allow retrying
            return Button {
                // Make sure we stop any existing security-scoped access before trying again
                stopSecurityScopedAccess()
                isShowingDocumentPicker = true
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    private func importSummaryView(report: BloodPressureReport) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Import Summary")
                .font(.headline)
            
            HStack(spacing: 10) {
                // Readings count
                dataBadge(
                    value: "\(totalReadingsCount)",
                    label: "Readings",
                    color: .blue
                )
                
                // Date range
                dataBadge(
                    value: dateRange(for: report),
                    label: "Date Range",
                    color: .purple
                )
                
                if duplicateCount > 0 {
                    // Duplicates
                    dataBadge(
                        value: "\(duplicateCount)",
                        label: "Duplicates",
                        color: .orange
                    )
                }
            }
            
            // NEW - BP Categories breakdown
            if !report.readings.isEmpty {
                bpCategoriesBreakdown(report: report)
            }
            
            if duplicateCount > 0 {
                Text("Note: \(duplicateCount) readings appear to be duplicates of readings you've already imported. These will be skipped to avoid duplicates in Apple Health.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            HStack(spacing: 20) {
                Label("User: \(report.memberName)", systemImage: "person")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !report.gender.isEmpty && report.gender != "Unknown" {
                    Label(report.gender, systemImage: "figure.stand")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.secondaryBackground)
        .cornerRadius(12)
    }
    
    // NEW - BP Categories breakdown
    private func bpCategoriesBreakdown(report: BloodPressureReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BP Classification Breakdown")
                .font(.subheadline)
                .padding(.top, 6)
            
            // Count readings by category
            let categoryCounts = countReadingsByCategory(report.readings)
            
            HStack(spacing: 8) {
                ForEach(Array(categoryCounts.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { category in
                    if let count = categoryCounts[category], count > 0 {
                        VStack(spacing: 4) {
                            Text("\(count)")
                                .font(.headline)
                                .foregroundColor(category.color)
                            
                            Text(category.rawValue)
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(category.color.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // Helper function to count readings by BP category
    private func countReadingsByCategory(_ readings: [BloodPressureReading]) -> [BPClassification: Int] {
        var counts: [BPClassification: Int] = [:]
        
        // Initialize counts for all categories
        for category in [BPClassification.normal, .elevated, .hypertensionStage1, .hypertensionStage2, .crisis] {
            counts[category] = 0
        }
        
        // Count readings by category
        for reading in readings {
            let classification = BPClassificationService.shared.classify(
                systolic: reading.systolic,
                diastolic: reading.diastolic
            )
            counts[classification, default: 0] += 1
        }
        
        return counts
    }
    
    private func dateRange(for report: BloodPressureReport) -> String {
        guard let firstDate = report.readings.map({ $0.date }).min(),
              let lastDate = report.readings.map({ $0.date }).max() else {
            return "N/A"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        return "\(dateFormatter.string(from: firstDate)) - \(dateFormatter.string(from: lastDate))"
    }
    
    // Helper function for consistent data badges
    private func dataBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    // Function to stop the security-scoped resource access
    private func stopSecurityScopedAccess() {
        if securityScopedAccessGranted, let _ = pdfURL {
            pdfURL?.stopAccessingSecurityScopedResource()
            securityScopedAccessGranted = false
        }
    }
    
    private func processImport(url: URL) {
        importStatus = .processing
        
        // This would normally be on a background thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let parser = PDFParserService()
            
            if let report = parser.parseHiloPDF(from: url) {
                // Store total readings count from the report
                totalReadingsCount = report.readings.count
                
                // Fix the duplicate detection logic
                // Create a more consistent identifier for readings
                let existingReadingIds = Set(dataStore.allReadings.map { createReadingIdentifier($0) })
                let newReadingIds = report.readings.map { createReadingIdentifier($0) }
                
                // Use a set to get unique IDs from the new readings
                let uniqueNewReadingIds = Set(newReadingIds)
                
                // Count how many readings already exist in our datastore
                duplicateCount = 0
                for readingId in uniqueNewReadingIds {
                    if existingReadingIds.contains(readingId) {
                        duplicateCount += 1
                    }
                }
                
                importedReport = report
                
                // Move to validation phase
                importStatus = .validating
                
                // Validate the data
                validateImportedData(report)
                
                // Mark import as successful
                importStatus = .success
            } else {
                importStatus = .failure
                // Stop accessing the security-scoped resource if processing failed
                stopSecurityScopedAccess()
            }
        }
    }
    
    // NEW - Data validation function
    private func validateImportedData(_ report: BloodPressureReport) {
        validationErrors = []
        var potentialIssues: [String] = []
        
        // Check for empty or missing readings
        if report.readings.isEmpty {
            potentialIssues.append("No blood pressure readings found in the report")
        }
        
        // Check reading date ranges
        if let firstDate = report.readings.map({ $0.date }).min(),
           let lastDate = report.readings.map({ $0.date }).max() {
            
            let calendar = Calendar.current
            let diff = calendar.dateComponents([.day], from: firstDate, to: lastDate)
            
            // Sanity check - warn if readings span more than 90 days
            if let days = diff.day, days > 90 {
                potentialIssues.append("Readings span \(days) days, which is unusually long")
            }
            
            // Warn if any readings are in the future
            let now = Date()
            if report.readings.contains(where: { $0.date > now }) {
                potentialIssues.append("Some readings have future dates")
            }
        }
        
        // Check for abnormal values
        var abnormalSystolicValues = 0
        var abnormalDiastolicValues = 0
        var abnormalHeartRates = 0
        var criticalBPCount = 0
        
        for reading in report.readings {
            // Check for extremely high or low systolic values
            if reading.systolic > 220 || reading.systolic < 70 {
                abnormalSystolicValues += 1
            }
            
            // Check for extremely high or low diastolic values
            if reading.diastolic > 130 || reading.diastolic < 40 {
                abnormalDiastolicValues += 1
            }
            
            // Check for very high or low heart rates
            if reading.heartRate > 150 || reading.heartRate < 40 {
                abnormalHeartRates += 1
            }
            
            // Count hypertensive crisis readings
            if reading.systolic >= 180 || reading.diastolic >= 120 {
                criticalBPCount += 1
            }
        }
        
        // Add warnings for abnormal values
        if abnormalSystolicValues > 0 {
            potentialIssues.append("\(abnormalSystolicValues) readings have unusual systolic values (outside 70-220 mmHg)")
        }
        
        if abnormalDiastolicValues > 0 {
            potentialIssues.append("\(abnormalDiastolicValues) readings have unusual diastolic values (outside 40-130 mmHg)")
        }
        
        if abnormalHeartRates > 0 {
            potentialIssues.append("\(abnormalHeartRates) readings have unusual heart rates (outside 40-150 bpm)")
        }
        
        // Set validation errors if any issues found
        if !potentialIssues.isEmpty {
            validationErrors = potentialIssues
            hasValidationError = true
        } else {
            hasValidationError = false
        }
        
        // Special handling for critical BP readings
        if criticalBPCount > 0 {
            criticalReadingsCount = criticalBPCount
            hasCriticalReadings = true
            hasCheckedReadings = true
        } else {
            hasCriticalReadings = false
        }
    }
    
    // Create a consistent identifier for a reading based on date, time and values
    private func createReadingIdentifier(_ reading: BloodPressureReading) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm"
        let dateString = dateFormatter.string(from: reading.date)
        
        return "\(dateString)-\(reading.systolic)-\(reading.diastolic)-\(reading.heartRate)"
    }
}
