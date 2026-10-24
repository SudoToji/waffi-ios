import CoreImage.CIFilterBuiltins
import SwiftUI

/// The ticket's QR and its order number, filling the screen so the customer can scan it from across the counter.
struct PagerQRView: View {
    let ticket: StaffTicket
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric private var numberSize = 72.0

    var body: some View {
        VStack(spacing: 20) {
            Text(ticket.number)
                .font(.system(size: numberSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .environment(\.layoutDirection, .leftToRight)
                .accessibilityLabel("Order \(ticket.number)")
            if let image = Self.qr(ticket.qrLink) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
                    // A QR is dark on light in every appearance.
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: 420)
                    .accessibilityLabel("QR code for order \(ticket.number)")
            }
            Text("Ask the customer to scan this code with their phone camera to follow their order.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Back to the pad") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private static func qr(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let image = CIContext().createCGImage(output, from: output.extent)
        else { return nil }
        return UIImage(cgImage: image)
    }
}
