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
    
    enum ImportStatus {
        case idle, processing, success, failure
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Status display
                statusView
                
                // PDF preview if available
                if let url = pdfURL, importStatus == .success {
                    PDFPreview(url: url)
                        .frame(height: 300)
                        .padding()
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
            .onDisappear {
                // Make sure we release security-scoped resource access when leaving the view
                stopSecurityScopedAccess()
            }
        }
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
                importStatus = .success
            } else {
                importStatus = .failure
                // Stop accessing the security-scoped resource if processing failed
                stopSecurityScopedAccess()
            }
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
