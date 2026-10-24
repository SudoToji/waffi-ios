import SwiftUI

/// The Business logo from the App Group, or the Waffi mark when there is none.
struct PagerLogoView: View {
    let businessName: String
    var size: CGFloat = 44
    /// A tile colour to sit the logo on (the Live Activity's brand colour); nil draws the logo alone.
    var tile: Color?
    /// Unused since the fallback became the Waffi mark; kept so callers need no change.
    var glyph: Color = .white
    /// A circle instead of a rounded square.
    var round = false

    var body: some View {
        Group {
            if let image = PagerLogo.image(forBusiness: businessName) {
                Image(uiImage: image).resizable().scaledToFill()
                    .background(tile ?? .clear)
            } else {
                WaffiMark(size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: round ? size / 2 : size * 0.22))
        .accessibilityHidden(true)
    }
}
