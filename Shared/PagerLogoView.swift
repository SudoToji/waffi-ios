import SwiftUI

/// The Business logo from the App Group, or the Waffi mark when there is none.
struct PagerLogoView: View {
    let businessName: String
    var size: CGFloat = 44
    /// A tile colour to sit the logo on (the Live Activity's brand colour); nil draws the logo alone.
    var tile: Color?
    /// The Waffi mark's colour, shown when there is no logo.
    var glyph: Color = .white
    /// A circle instead of a rounded square.
    var round = false

    var body: some View {
        Group {
            if let image = PagerLogo.image(forBusiness: businessName) {
                Image(uiImage: image).resizable().scaledToFill()
                    .background(tile ?? .clear)
            } else {
                Image(systemName: "bell.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(glyph)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(tile ?? Color.accentColor)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: round ? size / 2 : size * 0.22))
        .accessibilityHidden(true)
    }
}
