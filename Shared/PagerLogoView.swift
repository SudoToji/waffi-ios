import SwiftUI

/// The Business logo from the App Group, or the Waffi mark when there is none.
struct PagerLogoView: View {
    let businessName: String
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let image = PagerLogo.image(forBusiness: businessName) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "bell.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.accentColor)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        .accessibilityHidden(true)
    }
}
