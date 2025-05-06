import SwiftUI
import UniformTypeIdentifiers

struct PDFPickerView: UIViewControllerRepresentable {
    var onPDFPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Create a document picker for PDF files
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPDFPicked: onPDFPicked)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPDFPicked: (URL) -> Void
        
        init(onPDFPicked: @escaping (URL) -> Void) {
            self.onPDFPicked = onPDFPicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start security-scoped resource access
            let securitySuccess = url.startAccessingSecurityScopedResource()
            defer {
                if securitySuccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            onPDFPicked(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Handle cancellation if needed
        }
    }
}
