import ActivityKit
import SwiftUI
import WidgetKit

/// Placeholder lock-screen and Dynamic Island UI, shared by both widget extensions.
struct PagerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PagerActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.businessName).font(.headline)
                Text("#\(context.attributes.number) · \(context.state.state)")
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.businessName)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("#\(context.attributes.number)")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.state)
                }
            } compactLeading: {
                Text("#\(context.attributes.number)")
            } compactTrailing: {
                Text(context.state.state)
            } minimal: {
                Text(context.attributes.number)
            }
        }
    }
}
