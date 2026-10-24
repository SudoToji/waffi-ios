import SwiftUI
import VisionKit

/// The camera, reading QR codes with VisionKit. Calls `onScan` with the text of each new code; scans only while it is on screen.
struct QRScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    /// This iPhone has a camera VisionKit can read with, and the person has allowed it.
    @MainActor static var canScan: Bool { DataScannerViewController.isSupported && DataScannerViewController.isAvailable }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    func makeUIViewController(context: Context) -> ScannerController {
        let controller = ScannerController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])], qualityLevel: .balanced,
            recognizesMultipleItems: false, isHighFrameRateTrackingEnabled: false, isPinchToZoomEnabled: true,
            isGuidanceEnabled: false, isHighlightingEnabled: true)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: ScannerController, context: Context) {
        context.coordinator.onScan = onScan
    }

    final class ScannerController: DataScannerViewController {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            try? startScanning()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            stopScanning()
        }
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onScan: (String) -> Void

        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for case .barcode(let barcode) in addedItems {
                if let text = barcode.payloadStringValue {
                    onScan(text)
                    return
                }
            }
        }
    }
}
