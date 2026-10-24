import SwiftUI

/// Layout D: Arabic first, drawn right to left. A big Arabic headline next to the ring, the English line small underneath.
struct PagerArabicLayout: View {
    let attributes: PagerActivityAttributes
    let state: PagerState
    let palette: PagerPalette

    var body: some View {
        let words = attributes.style.wording.words(for: state)
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                PagerLogoView(businessName: attributes.businessName, size: 30, tile: palette.brand, glyph: palette.onBrand)
                HStack(spacing: 4) {
                    Text(attributes.businessName).font(.subheadline.weight(.bold)).foregroundStyle(palette.ink)
                    if !attributes.branchName.isEmpty {
                        Text(verbatim: "| \(attributes.branchName)").font(.subheadline).foregroundStyle(palette.secondary)
                    }
                }
                .lineLimit(1)
                Spacer(minLength: 8)
                PagerWaffiTag(palette: palette)
            }
            HStack(spacing: 14) {
                PagerRing(
                    number: attributes.number, color: palette.ring(state), filled: state == .ready,
                    size: 72, ink: palette.ink, onColor: palette.onBrand)
                VStack(alignment: .leading, spacing: 3) {
                    Text(words.ar)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(palette.status(state))
                        .lineLimit(2)
                    if let detail = words.detailAR {
                        Text(detail).font(.footnote).foregroundStyle(palette.ink.opacity(0.85))
                    }
                    Text(words.en)
                        .font(.caption)
                        .foregroundStyle(palette.secondary)
                        .environment(\.layoutDirection, .leftToRight)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
