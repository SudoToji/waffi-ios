import SwiftUI

/// A white, rounded, 50 pt text field with a thin border.
struct WaffiFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border))
    }
}

extension View {
    func waffiField() -> some View { modifier(WaffiFieldModifier()) }
}
