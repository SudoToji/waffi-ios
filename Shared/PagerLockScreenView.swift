import SwiftUI

/// The lock-screen card: "Business | Branch" and the WAFFI tag on top, the order number in a pager ring, the status in both languages.
/// Always light, so the text colours are fixed rather than the dark-mode-aware `.primary`.
struct PagerLockScreenView: View {
    static let background = Color(white: 0.96)
    private static let ink = Color(white: 0.1)

    let attributes: PagerActivityAttributes
    let state: PagerState

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(attributes.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Self.ink)
                    .lineLimit(1)
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    Circle().fill(.red).frame(width: 5, height: 5)
                    Text(verbatim: "WAFFI")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Color(white: 0.4))
                }
            }
            PagerRing(number: attributes.number, color: state.color, filled: state == .ready, ink: Self.ink)
            Text(state.bilingualMessage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(state.color)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
