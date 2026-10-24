import ActivityKit
import SwiftUI
import WidgetKit

/// The Pager Live Activity, shared by both widget extensions (the app's and the App Clip's). Live Activity only, no home-screen widget.
/// The Business's Card style (`PagerStyles/`) decides the lock-screen layout and gives the Dynamic Island its colour and wording.
struct PagerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PagerActivityAttributes.self) { context in
            let palette = PagerPalette(context.attributes.style)
            PagerLockScreenView(attributes: context.attributes, state: context.state.state)
                // Nil (a transparent style) lets the system's see-through material show.
                .activityBackgroundTint(palette.background)
                .activitySystemActionForegroundColor(palette.ink)
        } dynamicIsland: { context in
            let state = context.state.state
            // The Island is black, so the brand colour is checked against black.
            let palette = PagerPalette(context.attributes.style, island: true)
            let words = context.attributes.style.wording.words(for: state)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.title).font(.caption.weight(.semibold)).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        PagerRing(
                            number: context.attributes.number, color: palette.ring(state), filled: state == .ready,
                            size: 56, ink: palette.ink, onColor: palette.onBrand)
                        Text(verbatim: "\(words.en) · \(words.ar)")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(palette.status(state))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } compactLeading: {
                PagerRing(color: palette.ring(state), filled: state == .ready, size: 18)
            } compactTrailing: {
                Text(context.attributes.number).monospacedDigit().foregroundStyle(palette.status(state))
            } minimal: {
                Text(context.attributes.number)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(palette.status(state))
            }
            .keylineTint(palette.brand)
        }
    }
}
