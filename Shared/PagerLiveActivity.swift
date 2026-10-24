import ActivityKit
import SwiftUI
import WidgetKit

/// The Pager Live Activity, shared by both widget extensions (the app's and the App Clip's). Live Activity only, no home-screen widget.
struct PagerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PagerActivityAttributes.self) { context in
            PagerLockScreenView(attributes: context.attributes, state: context.state.state)
                .activityBackgroundTint(context.state.state.color.opacity(0.2))
        } dynamicIsland: { context in
            let state = context.state.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    PagerLogoView(businessName: context.attributes.businessName, size: 36)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.number)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.businessName).font(.headline).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Label(state.message, systemImage: state.symbol)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(state.color)
                }
            } compactLeading: {
                Text(context.attributes.number).monospacedDigit().foregroundStyle(state.color)
            } compactTrailing: {
                Circle().fill(state.color).frame(width: 10, height: 10)
            } minimal: {
                Image(systemName: state.symbol).foregroundStyle(state.color)
            }
            .keylineTint(state.color)
        }
    }
}
