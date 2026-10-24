import ActivityKit
import SwiftUI
import WidgetKit

/// The Pager Live Activity, shared by both widget extensions (the app's and the App Clip's). Live Activity only, no home-screen widget.
struct PagerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PagerActivityAttributes.self) { context in
            PagerLockScreenView(attributes: context.attributes, state: context.state.state)
                .activityBackgroundTint(PagerLockScreenView.background)
        } dynamicIsland: { context in
            let state = context.state.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.title).font(.caption.weight(.semibold)).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        PagerRing(number: context.attributes.number, color: state.color, filled: state == .ready, size: 56)
                        Text(state.bilingualMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(state.color)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } compactLeading: {
                PagerRing(color: state.color, filled: state == .ready, size: 18)
            } compactTrailing: {
                Text(context.attributes.number).monospacedDigit().foregroundStyle(state.color)
            } minimal: {
                Text(context.attributes.number)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(state.color)
            }
            .keylineTint(state.color)
        }
    }
}
