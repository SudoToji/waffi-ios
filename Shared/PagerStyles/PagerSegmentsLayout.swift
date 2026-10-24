import SwiftUI

/// Layout E: a card in the Business colour, Business and Branch with the number on top, a big status line and three bars.
/// Follows the phone language (English or Arabic), unlike the bilingual A to C.
struct PagerSegmentsLayout: View {
    let attributes: PagerActivityAttributes
    let state: PagerState
    let palette: PagerPalette
    @Environment(\.locale) private var locale

    /// Bars filled: 2 while waiting, all 3 when ready or ended.
    private var filled: Int { state == .waiting ? 2 : 3 }

    var body: some View {
        // Transparent has no brand fill to sit on, so the bars take the accent.
        let bar = attributes.style.background == .transparent ? palette.accent : palette.ink
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                PagerLogoView(businessName: attributes.businessName, size: 24, tile: palette.brand, glyph: palette.onBrand, round: true)
                Text(attributes.businessName).font(.system(size: 14, weight: .bold)).foregroundStyle(palette.ink).lineLimit(1)
                if !attributes.branchName.isEmpty {
                    Text(attributes.branchName).font(.system(size: 12)).foregroundStyle(palette.ink.opacity(0.75)).lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(verbatim: "\(locale.isArabic ? "رقم" : "No.") \(attributes.number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(palette.ink)
            }
            Text(attributes.style.wording.words(for: state).text(arabic: locale.isArabic))
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule().fill(index < filled ? bar : bar.opacity(0.22)).frame(height: 5)
                }
            }
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
