import SwiftUI

/// Layout A: the logo, name and Branch, the number in a pager ring, the status in both languages.
struct PagerRingLayout: View {
    let attributes: PagerActivityAttributes
    let state: PagerState
    let palette: PagerPalette

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                PagerLogoView(businessName: attributes.businessName, size: 48, tile: palette.brand, glyph: palette.onBrand)
                VStack(alignment: .leading, spacing: 2) {
                    PagerWaffiTag(palette: palette)
                    Text(attributes.businessName)
                        .font(.headline)
                        .foregroundStyle(palette.ink)
                        .lineLimit(1)
                    if !attributes.branchName.isEmpty {
                        Text(attributes.branchName).font(.caption).foregroundStyle(palette.secondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                PagerRing(
                    number: attributes.number, color: palette.ring(state), filled: state == .ready,
                    size: 60, ink: palette.ink, onColor: palette.onBrand)
            }
            palette.hairline.frame(height: 1)
            PagerStatusLine(words: attributes.style.wording.words(for: state), color: palette.status(state))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
