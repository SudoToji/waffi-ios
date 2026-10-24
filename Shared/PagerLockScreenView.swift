import SwiftUI

/// The lock-screen card: the Business's chosen layout (`PagerStyles/`), drawn for one state.
///
/// Layouts A to C are drawn left to right, D right to left, E and F by the phone language, whatever the phone's language, because the card is bilingual by design.
struct PagerLockScreenView: View {
    let attributes: PagerActivityAttributes
    let state: PagerState
    @Environment(\.locale) private var locale

    /// D is always right to left; E and F follow the phone language.
    private var rightToLeft: Bool {
        switch attributes.style.layout {
        case .arabic: true
        case .segments, .route: locale.isArabic
        default: false
        }
    }

    var body: some View {
        let palette = PagerPalette(attributes.style)
        Group {
            switch attributes.style.layout {
            case .ring: PagerRingLayout(attributes: attributes, state: state, palette: palette)
            case .stub: PagerStubLayout(attributes: attributes, state: state, palette: palette)
            case .track: PagerTrackLayout(attributes: attributes, state: state, palette: palette)
            case .arabic: PagerArabicLayout(attributes: attributes, state: state, palette: palette)
            case .segments: PagerSegmentsLayout(attributes: attributes, state: state, palette: palette)
            case .route: PagerRouteLayout(attributes: attributes, state: state, palette: palette)
            }
        }
        .environment(\.layoutDirection, rightToLeft ? .rightToLeft : .leftToRight)
        .accessibilityElement(children: .combine)
    }
}
