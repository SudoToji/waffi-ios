import SwiftUI

/// The three button looks of the staff app: solid green, tinted green, and white on the green QR screen.
struct WaffiButtonStyle: ButtonStyle {
    enum Kind { case primary, tinted, onBrand }

    let kind: Kind
    /// A small button that hugs its label (the Ready button on a ticket card).
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration, style: self)
    }

    private struct StyledLabel: View {
        let configuration: ButtonStyle.Configuration
        let style: WaffiButtonStyle
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            let radius: CGFloat = style.compact ? 12 : 14
            configuration.label
                .font((style.compact ? Font.subheadline : Font.headline).weight(.bold))
                .foregroundStyle(foreground)
                .padding(.horizontal, style.compact ? 18 : 0)
                .frame(maxWidth: style.compact ? nil : .infinity, minHeight: style.compact ? 44 : 54)
                .background(fill, in: RoundedRectangle(cornerRadius: radius))
                .opacity(isEnabled ? 1 : 0.5)
        }

        private var foreground: Color {
            switch style.kind {
            case .primary: Theme.onAccent
            case .tinted: Theme.accent
            case .onBrand: Theme.brand
            }
        }

        private var fill: Color {
            let pressed = configuration.isPressed
            switch style.kind {
            case .primary: return pressed ? Theme.accentPressed : Theme.accent
            case .tinted: return Theme.accentTint.opacity(pressed ? 0.7 : 1)
            case .onBrand: return Color.white.opacity(pressed ? 0.85 : 1)
            }
        }
    }
}

extension ButtonStyle where Self == WaffiButtonStyle {
    static var waffiPrimary: WaffiButtonStyle { WaffiButtonStyle(kind: .primary) }
    static var waffiTinted: WaffiButtonStyle { WaffiButtonStyle(kind: .tinted) }
    static var waffiOnBrand: WaffiButtonStyle { WaffiButtonStyle(kind: .onBrand) }
    static var waffiCompact: WaffiButtonStyle { WaffiButtonStyle(kind: .tinted, compact: true) }
}
