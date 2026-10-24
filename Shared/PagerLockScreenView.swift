import SwiftUI

/// The lock-screen card: the Business's chosen layout (`PagerStyles/`), drawn for one state.
///
/// Layouts A to C are drawn left to right and D right to left whatever the phone's language, because the card is bilingual by design.
struct PagerLockScreenView: View {
    let attributes: PagerActivityAttributes
    let state: PagerState

    var body: some View {
        let palette = PagerPalette(attributes.style)
        Group {
            switch attributes.style.layout {
            case .ring: PagerRingLayout(attributes: attributes, state: state, palette: palette)
            case .stub: PagerStubLayout(attributes: attributes, state: state, palette: palette)
            case .track: PagerTrackLayout(attributes: attributes, state: state, palette: palette)
            case .arabic: PagerArabicLayout(attributes: attributes, state: state, palette: palette)
            }
        }
        .environment(\.layoutDirection, attributes.style.layout == .arabic ? .rightToLeft : .leftToRight)
        .accessibilityElement(children: .combine)
    }
}
