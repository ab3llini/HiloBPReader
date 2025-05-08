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
                // Removed redundant Done button from navigation bar
            }
            .sheet(isPresented: $isShowingDocumentPicker) {
                PDFPickerView { url in
                    pdfURL = url
                    processImport(url: url)
                }
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
        // When it's the initial state, show a select button
        // When it's successful, show a done button
        // No "select different" or additional sync button needed
        
        if importStatus == .idle {
            // Initial select button
            Button {
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
            Button {
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
            Button {
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
                    value: "\(report.readings.count)",
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
    
    private func processImport(url: URL) {
        importStatus = .processing
        
        // This would normally be on a background thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let parser = PDFParserService()
            
            if let report = parser.parseHiloPDF(from: url) {
                // Check for duplicates against existing data
                let existingReadingIds = Set(dataStore.allReadings.map {
                    "\($0.date.timeIntervalSince1970)-\($0.systolic)-\($0.diastolic)"
                })
                
                let newReadingIds = Set(report.readings.map {
                    "\($0.date.timeIntervalSince1970)-\($0.systolic)-\($0.diastolic)"
                })
                
                // Count duplicates
                duplicateCount = newReadingIds.intersection(existingReadingIds).count
                
                importedReport = report
                importStatus = .success
            } else {
                importStatus = .failure
            }
        }
    }
    
    // Removed syncToHealthKit method as we're handling this on the main dashboard
}
