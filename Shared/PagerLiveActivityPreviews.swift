#if DEBUG
import SwiftUI
import WidgetKit

private func attributes(_ layout: PagerLayout, _ wording: PagerWording, _ color: String, number: String = "47",
                        background: PagerBackground = .solid, arabic: Bool = false) -> PagerActivityAttributes {
    PagerActivityAttributes(
        businessName: arabic ? "بين بار" : "Bean Bar", branchName: arabic ? "الزمالك" : "Zamalek", number: number,
        style: PagerStyle(layout: layout, wording: wording, color: color, background: background))
}

// The eight presets of the dashboard (layout, wording, colour).
private let ring = attributes(.ring, .order, "#2F766B")
private let stub = attributes(.stub, .order, "#2F766B")
private let track = attributes(.track, .order, "#2B2724")
private let arabic = attributes(.arabic, .order, "#2F766B", arabic: true)
private let coffee = attributes(.ring, .coffee, "#6F4E37", number: "67")
private let car = attributes(.track, .car, "#1D4ED8", number: "A12")
private let barber = attributes(.stub, .turn, "#C9A227", number: "14")
private let segments = attributes(.segments, .order, "#7A4A2A")
private let route = attributes(.route, .coffee, "#2E5A43")
private let restaurant = attributes(.arabic, .order, "#B4532A", number: "58", arabic: true)

/// The card on the lock screen: its own tint when solid, a wallpaper behind the system material when transparent.
private func lockScreen(_ attributes: PagerActivityAttributes, _ state: PagerState) -> some View {
    PagerLockScreenView(attributes: attributes, state: state)
        .background {
            if let tint = PagerPalette(attributes.style).background {
                tint
            } else {
                LinearGradient(colors: [.indigo, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding()
}

#Preview("A ring, waiting") { lockScreen(ring, .waiting) }
#Preview("A ring, ready") { lockScreen(ring, .ready) }
#Preview("B stub, waiting") { lockScreen(stub, .waiting) }
#Preview("B stub, ready") { lockScreen(stub, .ready) }
#Preview("C track, waiting") { lockScreen(track, .waiting) }
#Preview("C track, ready") { lockScreen(track, .ready) }
#Preview("D Arabic, waiting") { lockScreen(arabic, .waiting) }
#Preview("D Arabic, ready") { lockScreen(arabic, .ready) }

#Preview("E segments, waiting") { lockScreen(segments, .waiting) }
#Preview("E segments, ready") { lockScreen(segments, .ready) }
#Preview("F route, waiting") { lockScreen(route, .waiting) }
#Preview("F route, ready") { lockScreen(route, .ready) }
#Preview("F route, Arabic phone") {
    lockScreen(attributes(.route, .coffee, "#2E5A43", arabic: true), .ready)
        .environment(\.locale, Locale(identifier: "ar"))
}

#Preview("Coffee, waiting") { lockScreen(coffee, .waiting) }
#Preview("Coffee, ready") { lockScreen(coffee, .ready) }
#Preview("Car wash, waiting") { lockScreen(car, .waiting) }
#Preview("Car wash, ready") { lockScreen(car, .ready) }
#Preview("Barber, waiting") { lockScreen(barber, .waiting) }
#Preview("Barber, ready") { lockScreen(barber, .ready) }
#Preview("Restaurant, waiting") { lockScreen(restaurant, .waiting) }
#Preview("Restaurant, ready") { lockScreen(restaurant, .ready) }

#Preview("Transparent ring, ready") { lockScreen(attributes(.ring, .order, "#2F766B", background: .transparent), .ready) }
#Preview("Transparent stub, waiting") { lockScreen(attributes(.stub, .turn, "#C9A227", background: .transparent), .waiting) }
#Preview("Arabic phone, RTL") {
    lockScreen(arabic, .ready)
        .environment(\.locale, Locale(identifier: "ar"))
        .environment(\.layoutDirection, .rightToLeft)
}
#Preview("Ended") { lockScreen(ring, .ended) }

// The Dynamic Island presentations, through the widget itself.
#Preview("Compact", as: .dynamicIsland(.compact), using: coffee) {
    PagerLiveActivity()
} contentStates: {
    PagerActivityAttributes.ContentState(state: .waiting)
    PagerActivityAttributes.ContentState(state: .ready)
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: car) {
    PagerLiveActivity()
} contentStates: {
    PagerActivityAttributes.ContentState(state: .waiting)
    PagerActivityAttributes.ContentState(state: .ready)
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: barber) {
    PagerLiveActivity()
} contentStates: {
    PagerActivityAttributes.ContentState(state: .waiting)
    PagerActivityAttributes.ContentState(state: .ready)
    PagerActivityAttributes.ContentState(state: .ended)
}
#endif
