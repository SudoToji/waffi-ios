#if DEBUG
import SwiftUI
import WidgetKit

private let sample = PagerActivityAttributes(businessName: "Bean There", branchName: "Maadi", number: "47")
private let sampleArabic = PagerActivityAttributes(businessName: "قهوة وفي", branchName: "المعادي", number: "47")

private func lockScreen(_ attributes: PagerActivityAttributes, _ state: PagerState, language: String) -> some View {
    PagerLockScreenView(attributes: attributes, state: state)
        .background(state.color.opacity(0.2))
        .environment(\.locale, Locale(identifier: language))
        .environment(\.layoutDirection, language == "ar" ? .rightToLeft : .leftToRight)
}

#Preview("Waiting, English") { lockScreen(sample, .waiting, language: "en") }
#Preview("Ready, English") { lockScreen(sample, .ready, language: "en") }
#Preview("Ended, English") { lockScreen(sample, .ended, language: "en") }
#Preview("Waiting, Arabic") { lockScreen(sampleArabic, .waiting, language: "ar") }
#Preview("Ready, Arabic") { lockScreen(sampleArabic, .ready, language: "ar") }
#Preview("Ended, Arabic") { lockScreen(sampleArabic, .ended, language: "ar") }

// The Dynamic Island presentations, through the widget itself.
#Preview("Compact", as: .dynamicIsland(.compact), using: sample) {
    PagerLiveActivity()
} contentStates: {
    PagerActivityAttributes.ContentState(state: .waiting)
    PagerActivityAttributes.ContentState(state: .ready)
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: sample) {
    PagerLiveActivity()
} contentStates: {
    PagerActivityAttributes.ContentState(state: .waiting)
    PagerActivityAttributes.ContentState(state: .ready)
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: sample) {
    PagerLiveActivity()
} contentStates: {
    PagerActivityAttributes.ContentState(state: .waiting)
    PagerActivityAttributes.ContentState(state: .ready)
    PagerActivityAttributes.ContentState(state: .ended)
}
#endif
