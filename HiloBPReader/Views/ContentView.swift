import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var report: BloodPressureReport?
    @State private var isShowingDocumentPicker = false
    @State private var statusMessage = "Import a Hilo report to get started"
    
    private let pdfParser = PDFParserService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status message
                Text(statusMessage)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // Import button
                Button(action: {
                    isShowingDocumentPicker = true
                }) {
                    Text("Import Hilo Report")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Sync button
                Button(action: {
                    syncToHealthKit()
                }) {
                    Text("Sync to Apple Health")
                        .padding()
                        .background(report == nil ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(report == nil)
                
                // Report details if available
                if let report = report {
                    ReportDetailView(report: report)
                }
            }
            .navigationTitle("Hilo BP Reader")
            .sheet(isPresented: $isShowingDocumentPicker) {
                PDFPickerView(onPDFPicked: { url in
                    processPDF(url: url)
                })
            }
        }
    }
    
    private func processPDF(url: URL) {
        if let parsedReport = pdfParser.parseHiloPDF(from: url) {
            report = parsedReport
            statusMessage = "Imported report for \(parsedReport.memberName) with \(parsedReport.readings.count) readings"
        } else {
            statusMessage = "Failed to parse the PDF. Please make sure it's a valid Hilo report."
        }
    }
    
    private func syncToHealthKit() {
        guard let report = report else { return }
        
        statusMessage = "Syncing \(report.readings.count) readings to Apple Health..."
        healthKitManager.syncReadingsToHealthKit(report.readings)
    }
}
