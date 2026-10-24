import AVFoundation
import SwiftUI

/// The dark camera panel at the top of the Earn & redeem tab. Camera denied or missing: it says so and how to allow it; search and Manual Code still work.
struct ScanPanel: View {
    /// A lookup is running: the camera pauses reading.
    let busy: Bool
    let onScan: (String) -> Void

    private enum Access { case undetermined, allowed, denied }

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var access = ScanPanel.currentAccess
    @State private var torchOn = false

    private static var currentAccess: Access {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: .allowed
        case .notDetermined: .undetermined
        default: .denied
        }
    }

    private var hasTorch: Bool { AVCaptureDevice.default(for: .video)?.hasTorch == true }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.18, green: 0.27, blue: 0.22), Color(red: 0.07, green: 0.10, blue: 0.08)], startPoint: .top, endPoint: .bottom)
            if access == .allowed && QRScannerView.canScan {
                QRScannerView { text in if !busy { onScan(text) } }
                viewfinder
            } else if access == .undetermined {
                ProgressView().tint(.white)
            } else {
                unavailable
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .task {
            if access == .undetermined {
                access = await AVCaptureDevice.requestAccess(for: .video) ? .allowed : .denied
            }
        }
        // Coming back from Settings with the camera allowed.
        .onChange(of: scenePhase) {
            if scenePhase == .active { access = Self.currentAccess }
        }
        .onDisappear { setTorch(false) }
    }

    // MARK: Camera on

    private var viewfinder: some View {
        ZStack {
            CornerBrackets()
                .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 200, height: 200)
            Capsule().fill(Theme.ember).frame(width: 180, height: 2)
            if busy { ProgressView().tint(.white).controlSize(.large) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
        .overlay(alignment: .topLeading) {
            Label {
                Text("Camera on")
            } icon: {
                Circle().fill(.green).frame(width: 8, height: 8)
            }
            .font(.footnote.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.4), in: .capsule)
            .padding(14)
        }
        .overlay(alignment: .topTrailing) {
            if hasTorch {
                Button {
                    torchOn.toggle()
                    setTorch(torchOn)
                } label: {
                    Label("Torch", systemImage: torchOn ? "bolt.fill" : "bolt")
                        .labelStyle(.iconOnly)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.18), in: .circle)
                }
                .accessibilityValue(torchOn ? Text("On") : Text("Off"))
                .padding(10)
            }
        }
        .overlay(alignment: .bottom) {
            Text("Point at the Customer's Card QR")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.black.opacity(0.4), in: .capsule)
                .padding(14)
        }
    }

    // MARK: Camera off

    private var unavailable: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill").font(.largeTitle).accessibilityHidden(true)
            if access == .denied {
                Text("Camera access is off").font(.headline)
                Text("Allow the camera in Settings to scan Card QR codes. You can still search or type a Manual Code.")
                    .font(.subheadline)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .buttonStyle(.waffiOnBrand)
                .frame(maxWidth: 240)
            } else {
                Text("This iPhone cannot scan QR codes here").font(.headline)
                Text("Search for the Customer or type their Manual Code instead.").font(.subheadline)
            }
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding(20)
    }

    private func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {}
        if !on { torchOn = false }
    }
}

/// Four rounded corners of a square: the frame to hold the QR in.
private struct CornerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let arm = rect.width * 0.28
        let radius: CGFloat = 14
        var path = Path()
        // top-leading
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))
        // top-trailing
        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))
        // bottom-trailing
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))
        // bottom-leading
        path.move(to: CGPoint(x: rect.minX + arm, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arm))
        return path
    }
}
