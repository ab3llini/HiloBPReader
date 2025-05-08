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
    @State private var isAnimating = false
    
    enum ImportStatus {
        case idle, processing, success, failure
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Status display
                statusView
                    .padding(.vertical, 24)
                
                // PDF preview if available
                if let url = pdfURL, importStatus == .success {
                    Text("Report Preview")
                        .font(.headline)
                        .padding(.top)
                    
                    PDFPreview(url: url)
                        .frame(height: 280)
                        .padding(.horizontal)
                        .clipped()
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding([.horizontal, .bottom])
                }
                
                // Import results
                if let report = importedReport {
                    VStack {
                        Text("Import Summary")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            // Readings
                            VStack(spacing: 8) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                                
                                Text("\(report.readings.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Readings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Date Range
                            VStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 24))
                                    .foregroundColor(.purple)
                                
                                Text(dateRange)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text("Date Range")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Duplicates
                            VStack(spacing: 8) {
                                Image(systemName: duplicateCount > 0 ? "exclamationmark.triangle" : "checkmark.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(duplicateCount > 0 ? .orange : .green)
                                
                                Text("\(duplicateCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Duplicates")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background((duplicateCount > 0 ? Color.orange : Color.green).opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        if duplicateCount > 0 {
                            Text("Note: \(duplicateCount) readings appear to be duplicates of readings you've already imported. These will be skipped.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.top, 8)
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
                        .padding(.top, 12)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding([.horizontal, .bottom])
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    if importStatus == .idle || importStatus == .failure {
                        Button {
                            isShowingDocumentPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text(importStatus == .idle ? "Select PDF Report" : "Try Different PDF")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    } else if importStatus == .success {
                        HStack(spacing: 16) {
                            Button {
                                isShowingDocumentPicker = true
                            } label: {
                                Text("Different PDF")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemFill))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                            
                            Button {
                                dataStore.setCurrentReport(importedReport)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark")
                                    Text("Import Report")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationTitle("Import BP Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
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
                VStack(spacing: 16) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Import Your BP Report")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select a Hilo or Aktiia blood pressure PDF report to import your readings")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
            case .processing:
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .onAppear {
                            withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                                isAnimating = true
                            }
                        }
                }
                
                Text("Analyzing your report...")
                    .font(.headline)
                
                Text("Looking for blood pressure readings and metadata")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
            case .success:
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Report Analyzed Successfully")
                        .font(.headline)
                    
                    if let report = importedReport {
                        Text("Found \(report.readings.count) readings for \(report.memberName)")
                            .foregroundColor(.secondary)
                    }
                }
                
            case .failure:
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Could Not Process Report")
                        .font(.headline)
                    
                    Text("The selected file may not be a valid Hilo or Aktiia BP report")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private var dateRange: String {
        guard let report = importedReport,
              let firstDate = report.readings.map({ $0.date }).min(),
              let lastDate = report.readings.map({ $0.date }).max() else {
            return "N/A"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        return "\(dateFormatter.string(from: firstDate)) - \(dateFormatter.string(from: lastDate))"
    }
    
    private func processImport(url: URL) {
        importStatus = .processing
        
        // Simulate processing delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
}
