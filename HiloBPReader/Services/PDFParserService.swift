import Foundation
import PDFKit
import OSLog

class PDFParserService {
    private let logger = Logger(subsystem: "com.hilobpreader", category: "PDFParser")
    
    // MARK: - Public Methods
    
    /// Parse a Hilo/Aktiia blood pressure report PDF
    func parseHiloPDF(from url: URL) -> BloodPressureReport? {
        guard let document = PDFDocument(url: url) else {
            logger.error("Failed to create PDF document from URL: \(url.absoluteString)")
            return nil
        }
        
        logger.info("Starting to parse PDF with \(document.pageCount) pages")
        
        // Extract header info from first page
        guard let reportInfo = extractReportInfo(from: document) else {
            logger.error("Failed to extract basic report information")
            return nil
        }
        
        // Extract all readings from all pages
        var allReadings: [BloodPressureReading] = []
        
        // Process each page (starting from page 1, which is the second page in 1-indexed view)
        for i in 1..<document.pageCount {
            guard let page = document.page(at: i) else {
                logger.warning("Could not access page at index \(i)")
                continue
            }
            
            let pageReadings = extractReadingsFromPage(page)
            logger.info("Extracted \(pageReadings.count) readings from page \(i+1)")
            allReadings.append(contentsOf: pageReadings)
        }
        
        // Create the final report
        var report = reportInfo
        report.readings = allReadings
        logger.info("Successfully parsed report with \(allReadings.count) total readings")
        
        return report
    }
    
    // MARK: - Private Extraction Methods
    
    /// Extract basic report information from the first page
    private func extractReportInfo(from document: PDFDocument) -> BloodPressureReport? {
        guard let firstPage = document.page(at: 0),
              let firstPageText = firstPage.string else {
            logger.error("Failed to extract text from first page")
            return nil
        }
        
        logger.debug("Extracting report info from first page text")
        
        // Use safer extraction methods with fallbacks
        let name = extractMemberName(from: firstPageText)
        let email = extractEmail(from: firstPageText)
        let monthYear = extractMonthYear(from: firstPageText)
        let gender = extractGender(from: firstPageText)
        let dob = extractDateOfBirth(from: firstPageText)
        let physicalInfo = extractPhysicalInfo(from: firstPageText)
        
        // Parse summary stats
        let summaryStats = extractSummaryStats(from: firstPageText)
        
        return BloodPressureReport(
            memberName: name,
            email: email,
            month: monthYear.month,
            year: monthYear.year,
            gender: gender,
            dateOfBirth: dob,
            height: physicalInfo.height,
            weight: physicalInfo.weight,
            summaryStats: summaryStats,
            readings: []
        )
    }
    
    /// Extract readings from a page by splitting it into sections and processing each table
    private func extractReadingsFromPage(_ page: PDFPage) -> [BloodPressureReading] {
        guard let pageText = page.string else {
            logger.warning("Page has no text content")
            return []
        }
        
        var readings: [BloodPressureReading] = []
        
        // First split the page text into left and right columns (if it has two columns)
        let columns = splitIntoColumns(pageText)
        
        // Process each column
        for columnText in columns {
            let columnReadings = extractReadingsFromColumnText(columnText)
            readings.append(contentsOf: columnReadings)
        }
        
        // If we didn't find any readings with the column approach, try the whole page
        if readings.isEmpty {
            readings = extractReadingsFromColumnText(pageText)
        }
        
        return readings
    }
    
    /// Try to split page text into left and right columns
    private func splitIntoColumns(_ pageText: String) -> [String] {
        // This is a heuristic approach to split columns
        // In production, you might need a more sophisticated method based on physical layout
        
        // Look for patterns that indicate the start of a new column
        if let dateRange = pageText.range(of: "DATE\\s+TIME\\s+SBP\\s+DBP\\s+HR\\s+DATE\\s+TIME\\s+SBP\\s+DBP\\s+HR", options: .regularExpression) {
            let headerPart = String(pageText[..<dateRange.upperBound])
            let tablePart = String(pageText[dateRange.upperBound...])
            
            // Try to find a natural split in the middle of the line
            let lines = tablePart.components(separatedBy: .newlines)
            var leftColumnText = headerPart
            var rightColumnText = ""
            
            for line in lines {
                // Try to detect if a line contains two rows side by side
                let pattern = "(\\d{1,2})\\s+\\w+,\\s+(\\d{2})\\s+(\\d{2}:\\d{2})\\s+(\\d{3})\\s+(\\d{2})\\s+(\\d{2})\\s+(\\d{1,2})\\s+\\w+,\\s+(\\d{2})"
                if let range = line.range(of: pattern, options: .regularExpression) {
                    // This line likely contains two rows - split near the middle
                    let splitIndex = line.index(line.startIndex, offsetBy: line.count / 2)
                    leftColumnText.append(String(line[..<splitIndex]) + "\n")
                    rightColumnText.append(String(line[splitIndex...]) + "\n")
                } else {
                    // Just add to left column if we can't detect a split
                    leftColumnText.append(line + "\n")
                }
            }
            
            return [leftColumnText, rightColumnText]
        }
        
        // If we couldn't split, return the whole text as one column
        return [pageText]
    }
    
    /// Extract readings from a column of text using regex
    private func extractReadingsFromColumnText(_ text: String) -> [BloodPressureReading] {
        var readings: [BloodPressureReading] = []
        
        // Look for lines matching our expected format for BP readings
        let pattern = "(\\d{1,2})\\s+(\\w+),\\s+(\\d{2})\\s+(\\d{1,2}:\\d{2})\\s+(\\d{1,3})\\s+(\\d{1,2})\\s+(\\d{1,2})"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches {
                if match.numberOfRanges < 8 {
                    logger.warning("Regex match didn't capture all expected groups")
                    continue
                }
                
                guard let dayRange = Range(match.range(at: 1), in: text),
                      let monthRange = Range(match.range(at: 2), in: text),
                      let yearRange = Range(match.range(at: 3), in: text),
                      let timeRange = Range(match.range(at: 4), in: text),
                      let sbpRange = Range(match.range(at: 5), in: text),
                      let dbpRange = Range(match.range(at: 6), in: text),
                      let hrRange = Range(match.range(at: 7), in: text) else {
                    logger.warning("Failed to convert NSRange to Range")
                    continue
                }
                
                let day = String(text[dayRange])
                let month = String(text[monthRange])
                let year = String(text[yearRange])
                let time = String(text[timeRange])
                let sbp = String(text[sbpRange])
                let dbp = String(text[dbpRange])
                let hr = String(text[hrRange])
                
                // Determine the reading type
                let readingType = determineReadingType(text, at: match.range.location)
                
                // Create date from components
                guard let date = createDate(day: day, month: month, year: year) else {
                    logger.warning("Failed to create date from components: \(day) \(month) \(year)")
                    continue
                }
                
                // Create the reading
                let reading = BloodPressureReading(
                    date: date,
                    time: time,
                    systolic: Int(sbp) ?? 0,
                    diastolic: Int(dbp) ?? 0,
                    heartRate: Int(hr) ?? 0,
                    readingType: readingType
                )
                
                readings.append(reading)
            }
        } catch {
            logger.error("Regex error: \(error.localizedDescription)")
        }
        
        return readings
    }
    
    // MARK: - Helper Methods
    
    /// Create a Date object from day, month, year strings
    private func createDate(day: String, month: String, year: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yy"
        
        // Ensure we have two digits for year
        let yearStr = year.count == 2 ? year : year.suffix(2).description
        let dateStr = "\(day) \(month) \(yearStr)"
        
        return dateFormatter.date(from: dateStr)
    }
    
    /// Determine reading type based on icons/markers near the reading
    private func determineReadingType(_ text: String, at position: Int) -> BloodPressureReading.ReadingType {
        // Search a few lines before and after for markers
        let startPosition = max(0, position - 100)
        let endPosition = min(text.count, position + 100)
        
        let range = NSRange(location: startPosition, length: endPosition - startPosition)
        let searchText = (text as NSString).substring(with: range)
        
        if searchText.contains("Initialization with cuff") {
            return .initialization
        } else if searchText.contains("Cuff measurement") {
            return .cuffMeasurement
        } else if searchText.contains("On demand phone measurement") {
            return .onDemandPhone
        }
        
        return .normal
    }
    
    /// Extract the member name from first page
    private func extractMemberName(from text: String) -> String {
        let patterns = [
            "Monthly Report\\s+([^\\n]+)",
            "Alberto Bellini"  // Fallback for specific name from the sample PDF
        ]
        
        for pattern in patterns {
            if let name = extractUsingRegex(text, pattern: pattern) {
                return name.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return "Unknown User"
    }
    
    /// Extract email address from first page
    private func extractEmail(from text: String) -> String {
        if let email = extractUsingRegex(text, pattern: "([\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,})") {
            return email
        }
        return "unknown@email.com"
    }
    
    /// Extract month and year from first page
    private func extractMonthYear(from text: String) -> (month: String, year: String) {
        if let monthYearStr = extractUsingRegex(text, pattern: "(\\w+),\\s+(\\d{4})") {
            let components = monthYearStr.components(separatedBy: ", ")
            if components.count == 2 {
                return (components[0], components[1])
            }
        }
        
        // Try another pattern
        if let monthStr = extractUsingRegex(text, pattern: "(January|February|March|April|May|June|July|August|September|October|November|December)"),
           let yearStr = extractUsingRegex(text, pattern: "(202[0-9])") {
            return (monthStr, yearStr)
        }
        
        return ("Unknown", "Unknown")
    }
    
    /// Extract gender from first page
    private func extractGender(from text: String) -> String {
        if let gender = extractUsingRegex(text, pattern: "(Male|Female)") {
            return gender
        }
        return "Unknown"
    }
    
    /// Extract date of birth from first page
    private func extractDateOfBirth(from text: String) -> String {
        if let dob = extractUsingRegex(text, pattern: "(\\d{1,2})\\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+(\\d{4})") {
            return dob
        }
        return "Unknown"
    }
    
    /// Extract height and weight from first page
    private func extractPhysicalInfo(from text: String) -> (height: String, weight: String) {
        let height = extractUsingRegex(text, pattern: "(\\d+)\\s+cm") ?? "Unknown"
        let weight = extractUsingRegex(text, pattern: "(\\d+)\\s+kg") ?? "Unknown"
        return (height, weight)
    }
    
    /// Extract summary statistics from the summary table
    private func extractSummaryStats(from text: String) -> BloodPressureReport.SummaryStats? {
        guard text.contains("Summary table") else {
            logger.warning("Summary table not found in text")
            return nil
        }
        
        // This is a more targeted approach to extract specific values
        let daytimeSys = extractIntFromSummaryTable(text, label: "Daytime", column: "Sys", defaultValue: 0)
        let daytimeDia = extractIntFromSummaryTable(text, label: "Daytime", column: "Dia", defaultValue: 0)
        let daytimeHR = extractIntFromSummaryTable(text, label: "Daytime", column: "HR", defaultValue: 0)
        
        let nighttimeSys = extractIntFromSummaryTable(text, label: "Night-time", column: "Sys", defaultValue: 0)
        let nighttimeDia = extractIntFromSummaryTable(text, label: "Night-time", column: "Dia", defaultValue: 0)
        let nighttimeHR = extractIntFromSummaryTable(text, label: "Night-time", column: "HR", defaultValue: 0)
        
        let allSys = extractIntFromSummaryTable(text, label: "All measurements", column: "Sys", defaultValue: 0)
        let allDia = extractIntFromSummaryTable(text, label: "All measurements", column: "Dia", defaultValue: 0)
        let allHR = extractIntFromSummaryTable(text, label: "All measurements", column: "HR", defaultValue: 0)
        
        return BloodPressureReport.SummaryStats(
            daytimeSystolicMean: daytimeSys,
            daytimeDiastolicMean: daytimeDia,
            daytimeHeartRateMean: daytimeHR,
            nighttimeSystolicMean: nighttimeSys,
            nighttimeDiastolicMean: nighttimeDia,
            nighttimeHeartRateMean: nighttimeHR,
            overallSystolicMean: allSys,
            overallDiastolicMean: allDia,
            overallHeartRateMean: allHR
        )
    }
    
    /// Extract a specific integer value from the summary table
    private func extractIntFromSummaryTable(_ text: String, label: String, column: String, defaultValue: Int) -> Int {
        // First find the table section
        guard let tableRange = text.range(of: "Summary table") else { return defaultValue }
        let tableText = String(text[tableRange.upperBound...])
        
        // Use a more specific pattern to find the value in the right row and column
        // This is a simplified approach - in production you might need a more sophisticated table parser
        let rowPattern = "\(label).*?Mean\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)"
        
        guard let regex = try? NSRegularExpression(pattern: rowPattern, options: [.dotMatchesLineSeparators]) else {
            return defaultValue
        }
        
        let range = NSRange(tableText.startIndex..<tableText.endIndex, in: tableText)
        guard let match = regex.firstMatch(in: tableText, options: [], range: range) else {
            return defaultValue
        }
        
        // Determine which capture group to use based on column
        var groupIndex: Int
        switch column {
        case "Sys": groupIndex = 1
        case "Dia": groupIndex = 2
        case "HR": groupIndex = 3
        default: return defaultValue
        }
        
        guard match.numberOfRanges > groupIndex,
              let valueRange = Range(match.range(at: groupIndex), in: tableText),
              let value = Int(tableText[valueRange]) else {
            return defaultValue
        }
        
        return value
    }
    
    /// Safe extraction using regex with proper error handling
    private func extractUsingRegex(_ text: String, pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            guard let match = regex.firstMatch(in: text, options: [], range: range) else {
                return nil
            }
            
            // If the pattern has a capture group, extract it
            if match.numberOfRanges > 1, let captureRange = Range(match.range(at: 1), in: text) {
                return String(text[captureRange])
            }
            
            // Otherwise return the entire matched string
            if let matchedRange = Range(match.range, in: text) {
                return String(text[matchedRange])
            }
            
            return nil
        } catch {
            logger.error("Regex error: \(error.localizedDescription)")
            return nil
        }
    }
}
