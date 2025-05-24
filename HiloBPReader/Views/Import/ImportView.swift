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
    @State private var animateContent = false
    @State private var importProgress: Double = 0
    
    @State private var securityScopedAccessGranted = false
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
            ZStack {
                Color.primaryBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                            .padding(.top, 20)
                        
                        // Main content based on status
                        mainContentView
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        
                        // Validation warnings
                        if hasValidationError {
                            validationErrorView
                                .transition(.push(from: .top).combined(with: .opacity))
                        }
                        
                        // Critical readings warning
                        if hasCriticalReadings, let report = importedReport {
                            criticalReadingsView(report: report)
                                .transition(.push(from: .top).combined(with: .opacity))
                        }
                        
                        // Import results
                        if importStatus == .success, let report = importedReport {
                            importSummaryView(report: report)
                                .transition(.push(from: .bottom).combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                
                // Bottom action area
                VStack {
                    Spacer()
                    actionButtonsView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.primaryBackground.opacity(0),
                                    Color.primaryBackground
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                            .ignoresSafeArea()
                        )
                }
            }
            .navigationBarHidden(true)
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
                    hasCriticalReadings = false
                }
            } message: {
                Text("The report contains \(criticalReadingsCount) readings in the Hypertensive Crisis range. Please confirm these are correct before importing.")
            }
            .onDisappear {
                stopSecurityScopedAccess()
            }
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animateContent = true
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primaryAccent)
            }
            
            Spacer()
            
            Text("Import Report")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            Spacer()
            
            // Placeholder for balance
            Text("Cancel")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.clear)
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        switch importStatus {
        case .idle:
            idleStateView
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.9)
                .animation(.spring(response: 0.6), value: animateContent)
            
        case .processing, .validating:
            processingStateView
            
        case .success:
            if let url = pdfURL {
                successStateView(url: url)
            }
            
        case .failure:
            failureStateView
        }
    }
    
    private var idleStateView: some View {
        VStack(spacing: 32) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.primaryAccent.opacity(0.1), Color.primaryAccent.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "doc.viewfinder.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.primaryAccent, Color.secondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .symbolEffect(.pulse.wholeSymbol)
            }
            
            VStack(spacing: 12) {
                Text("Import Your Hilo Report")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Select a PDF report from Hilo to import\nyour blood pressure readings")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondaryText)
            }
            
            // Features list
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .successAccent,
                    title: "Automatic data extraction",
                    description: "We'll read your BP values from the PDF"
                )
                
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .primaryAccent,
                    title: "Instant visualization",
                    description: "See trends and patterns immediately"
                )
                
                FeatureRow(
                    icon: "heart.text.square.fill",
                    iconColor: .dangerAccent,
                    title: "Apple Health sync",
                    description: "Optional integration with Health app"
                )
            }
            .padding(.top, 24)
        }
    }
    
    private var processingStateView: some View {
        VStack(spacing: 24) {
            // Animated loader
            ZStack {
                Circle()
                    .stroke(Color.glassBorder, lineWidth: 3)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: importProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.primaryAccent, Color.secondaryAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: importProgress)
                
                Image(systemName: importStatus == .validating ? "checkmark.shield.fill" : "doc.text.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.primaryAccent, Color.secondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .symbolEffect(.pulse)
            }
            .onAppear {
                simulateProgress()
            }
            
            VStack(spacing: 8) {
                Text(importStatus == .validating ? "Validating Data" : "Processing Report")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Text(importStatus == .validating ? "Checking data integrity..." : "Extracting blood pressure readings...")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
        }
    }
    
    private func successStateView(url: URL) -> some View {
        VStack(spacing: 24) {
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.successAccent.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.successAccent)
                    .symbolEffect(.bounce)
            }
            
            VStack(spacing: 8) {
                Text("Import Successful!")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Text("Your readings have been imported")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            
            // PDF preview
            if let _ = pdfURL {
                PDFPreview(url: url)
                    .frame(height: 200)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.glassBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            }
        }
    }
    
    private var failureStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.dangerAccent.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.dangerAccent)
                    .symbolEffect(.bounce)
            }
            
            VStack(spacing: 8) {
                Text("Import Failed")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Text("Unable to process the PDF file")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
        }
    }
    
    private var validationErrorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.warningAccent)
                
                Text("Validation Warnings")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(validationErrors, id: \.self) { error in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.warningAccent)
                            .frame(width: 4, height: 4)
                            .offset(y: 6)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.warningAccent.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.warningAccent.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func criticalReadingsView(report: BloodPressureReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.dangerAccent)
                
                Text("Critical Blood Pressure Readings")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Spacer()
            }
            
            Text("This report contains \(criticalReadingsCount) readings in the Hypertensive Crisis range (≥180/120 mmHg).")
                .font(.subheadline)
                .foregroundColor(.primaryText)
            
            Text("Please verify these readings are correct. If accurate, consult with a healthcare provider.")
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.dangerAccent.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.dangerAccent.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func importSummaryView(report: BloodPressureReport) -> some View {
        VStack(spacing: 16) {
            // Summary cards
            HStack(spacing: 12) {
                SummaryCard(
                    icon: "doc.text.fill",
                    value: "\(totalReadingsCount)",
                    label: "Readings",
                    color: .primaryAccent
                )
                
                SummaryCard(
                    icon: "calendar",
                    value: dateRange(for: report),
                    label: "Date Range",
                    color: .secondaryAccent
                )
                
                if duplicateCount > 0 {
                    SummaryCard(
                        icon: "exclamationmark.circle.fill",
                        value: "\(duplicateCount)",
                        label: "Duplicates",
                        color: .warningAccent
                    )
                }
            }
            
            // BP breakdown
            if !report.readings.isEmpty {
                bpCategoriesBreakdown(report: report)
            }
            
            // User info
            HStack {
                Label(report.memberName, systemImage: "person.fill")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                if !report.gender.isEmpty && report.gender != "Unknown" {
                    Label(report.gender, systemImage: "figure.stand")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private var actionButtonsView: some View {
        switch importStatus {
        case .idle:
            ActionButton(
                title: "Select PDF",
                icon: "doc.badge.plus",
                style: .primary
            ) {
                isShowingDocumentPicker = true
            }
            
        case .success:
            ActionButton(
                title: "Done",
                icon: "checkmark",
                style: .primary
            ) {
                dataStore.setCurrentReport(importedReport)
                dismiss()
            }
            
        case .failure:
            ActionButton(
                title: "Try Again",
                icon: "arrow.clockwise",
                style: .primary
            ) {
                stopSecurityScopedAccess()
                importStatus = .idle
                isShowingDocumentPicker = true
            }
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func simulateProgress() {
        importProgress = 0
        withAnimation(.linear(duration: 2)) {
            importProgress = 0.9
        }
    }
    
    private func processImport(url: URL) {
        importStatus = .processing
        importProgress = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let parser = PDFParserService()
            
            if let report = parser.parseHiloPDF(from: url) {
                totalReadingsCount = report.readings.count
                
                let existingReadingIds = Set(dataStore.allReadings.map { createReadingIdentifier($0) })
                let newReadingIds = report.readings.map { createReadingIdentifier($0) }
                let uniqueNewReadingIds = Set(newReadingIds)
                
                duplicateCount = 0
                for readingId in uniqueNewReadingIds {
                    if existingReadingIds.contains(readingId) {
                        duplicateCount += 1
                    }
                }
                
                importedReport = report
                importStatus = .validating
                
                validateImportedData(report)
                
                withAnimation(.spring(response: 0.5)) {
                    importStatus = .success
                }
            } else {
                withAnimation(.spring(response: 0.5)) {
                    importStatus = .failure
                }
                stopSecurityScopedAccess()
            }
        }
    }
    
    // Keep existing helper methods...
    private func stopSecurityScopedAccess() {
        if securityScopedAccessGranted, let _ = pdfURL {
            pdfURL?.stopAccessingSecurityScopedResource()
            securityScopedAccessGranted = false
        }
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
    
    private func bpCategoriesBreakdown(report: BloodPressureReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Classification Breakdown")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            let categoryCounts = countReadingsByCategory(report.readings)
            
            VStack(spacing: 8) {
                ForEach(Array(categoryCounts.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { category in
                    if let count = categoryCounts[category], count > 0 {
                        CategoryRow(
                            category: category,
                            count: count,
                            total: totalReadingsCount
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.glassBorder, lineWidth: 1)
                )
        )
    }
    
    private func validateImportedData(_ report: BloodPressureReport) {
        // Keep existing validation logic
        validationErrors = []
        var potentialIssues: [String] = []
        
        if report.readings.isEmpty {
            potentialIssues.append("No blood pressure readings found in the report")
        }
        
        if let firstDate = report.readings.map({ $0.date }).min(),
           let lastDate = report.readings.map({ $0.date }).max() {
            
            let calendar = Calendar.current
            let diff = calendar.dateComponents([.day], from: firstDate, to: lastDate)
            
            if let days = diff.day, days > 90 {
                potentialIssues.append("Readings span \(days) days, which is unusually long")
            }
            
            let now = Date()
            if report.readings.contains(where: { $0.date > now }) {
                potentialIssues.append("Some readings have future dates")
            }
        }
        
        var criticalBPCount = 0
        
        for reading in report.readings {
            if reading.systolic >= 180 || reading.diastolic >= 120 {
                criticalBPCount += 1
            }
        }
        
        if !potentialIssues.isEmpty {
            validationErrors = potentialIssues
            hasValidationError = true
        } else {
            hasValidationError = false
        }
        
        if criticalBPCount > 0 {
            criticalReadingsCount = criticalBPCount
            hasCriticalReadings = true
            hasCheckedReadings = true
        } else {
            hasCriticalReadings = false
        }
    }
    
    private func countReadingsByCategory(_ readings: [BloodPressureReading]) -> [BPClassification: Int] {
        var counts: [BPClassification: Int] = [:]
        
        for category in [BPClassification.normal, .elevated, .hypertensionStage1, .hypertensionStage2, .crisis] {
            counts[category] = 0
        }
        
        for reading in readings {
            let classification = BPClassificationService.shared.classify(
                systolic: reading.systolic,
                diastolic: reading.diastolic
            )
            counts[classification, default: 0] += 1
        }
        
        return counts
    }
    
    private func createReadingIdentifier(_ reading: BloodPressureReading) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm"
        let dateString = dateFormatter.string(from: reading.date)
        
        return "\(dateString)-\(reading.systolic)-\(reading.diastolic)-\(reading.heartRate)"
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primaryText)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct CategoryRow: View {
    let category: BPClassification
    let count: Int
    let total: Int
    
    private var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    private var categoryColor: Color {
        switch category {
        case .normal: return .bpNormal
        case .elevated: return .bpElevated
        case .hypertensionStage1: return .bpStage1
        case .hypertensionStage2: return .bpStage2
        case .crisis: return .bpCrisis
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 8, height: 8)
                    
                    Text(category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
                
                Text("\(count) (\(Int(percentage * 100))%)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.glassBorder)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(categoryColor)
                        .frame(width: geometry.size.width * percentage, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
