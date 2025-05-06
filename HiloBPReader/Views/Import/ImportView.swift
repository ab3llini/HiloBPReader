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
                    ImportSummaryView(
                        report: report,
                        duplicateCount: duplicateCount
                    )
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
                
                if importStatus == .success {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dataStore.setCurrentReport(importedReport)
                            dismiss()
                        }
                        .fontWeight(.bold)
                    }
                }
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
        HStack {
            // Import button
            Button {
                isShowingDocumentPicker = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text(importStatus == .idle ? "Select PDF" : "Select Different PDF")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            if importStatus == .success {
                // Sync button
                Button {
                    syncToHealthKit()
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Sync to Health")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
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
    
    private func syncToHealthKit() {
        guard let report = importedReport else { return }
        dataStore.setCurrentReport(report)
        dismiss()
    }
}
