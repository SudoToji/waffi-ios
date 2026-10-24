import CoreImage.CIFilterBuiltins
import SwiftUI

/// The ticket's QR and its order number, filling the screen so the customer can scan it from across the counter.
struct PagerQRView: View {
    let ticket: StaffTicket
    /// "Business · Branch".
    let place: String
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric private var numberSize = 72.0

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text(verbatim: place)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.onBrandSecondary)
                Spacer()
                Button("Close", systemImage: "xmark") { dismiss() }
                    .labelStyle(.iconOnly)
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.14), in: .circle)
            }

            VStack(spacing: 2) {
                Text("Order")
                    .textCase(.uppercase)
                    .font(.footnote.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(Theme.onBrandSecondary)
                Text(ticket.number)
                    .font(.system(size: numberSize, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .environment(\.layoutDirection, .leftToRight)
                    .accessibilityLabel("Order \(ticket.number)")
            }
            .padding(.top, 8)

            if let image = Self.qr(ticket.qrLink) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 230)
                    .padding(22)
                    // A QR is dark on light in every appearance.
                    .background(.white, in: RoundedRectangle(cornerRadius: 28))
                    .accessibilityLabel("QR code for order \(ticket.number)")
            }

            VStack(spacing: 4) {
                // Both languages are always shown: the customer reads this, not the staff member.
                Text("Scan with your phone camera")
                    .font(.headline.weight(.bold))
                    .environment(\.locale, Locale(identifier: "en"))
                Text(verbatim: "امسح الكود بكاميرا موبايلك")
                    .font(.headline)
                    .foregroundStyle(Theme.onBrandSecondary)
                    .environment(\.locale, Locale(identifier: "ar"))
                Text("We'll alert you when your order is ready")
                    .font(.footnote)
                    .foregroundStyle(Theme.onBrandSecondary)
                    .padding(.top, 4)
            }
            .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            Button("Done, next order") { dismiss() }
                .buttonStyle(.waffiOnBrand)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.brand.ignoresSafeArea())
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
