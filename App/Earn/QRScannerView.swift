import SwiftUI
import VisionKit

/// The camera, reading QR codes with VisionKit. Calls `onScan` with the text of each new code; scans only while it is on screen.
struct QRScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    /// This iPhone has a camera VisionKit can read with, and the person has allowed it.
    @MainActor static var canScan: Bool { DataScannerViewController.isSupported && DataScannerViewController.isAvailable }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    func makeUIViewController(context: Context) -> ScannerHost {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])], qualityLevel: .balanced,
            recognizesMultipleItems: false, isHighFrameRateTrackingEnabled: false, isPinchToZoomEnabled: true,
            isGuidanceEnabled: false, isHighlightingEnabled: true)
        scanner.delegate = context.coordinator
        return ScannerHost(scanner: scanner)
    }

    func updateUIViewController(_ host: ScannerHost, context: Context) {
        context.coordinator.onScan = onScan
    }

    /// Holds the scanner as a child: VisionKit's controller cannot be subclassed, and it must start once it is on screen.
    final class ScannerHost: UIViewController {
        private let scanner: DataScannerViewController

        init(scanner: DataScannerViewController) {
            self.scanner = scanner
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

        override func viewDidLoad() {
            super.viewDidLoad()
            addChild(scanner)
            scanner.view.frame = view.bounds
            scanner.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(scanner.view)
            scanner.didMove(toParent: self)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            try? scanner.startScanning()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            scanner.stopScanning()
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
