import SwiftUI

/// How each state looks: the colour change, the symbol and the status line.
extension PagerState {
    var color: Color {
        switch self {
        case .waiting: .orange
        case .ready: .green
        case .ended: .gray
        }
    }

    var symbol: String {
        switch self {
        case .waiting: "hourglass"
        case .ready: "checkmark.circle.fill"
        case .ended: "checkmark"
        }
    }

    var message: LocalizedStringKey {
        switch self {
        case .waiting: "Preparing your order"
        case .ready: "Ready, collect your order"
        case .ended: "Order complete"
        }
    }

    /// The Live Activity's status line: both languages at once, so it is not localized per phone language.
    var bilingualMessage: String {
        switch self {
        case .waiting: "Preparing · قيد التحضير"
        case .ready: "Ready, collect your order · طلبك جاهز"
        case .ended: "Ended · انتهى"
        }
    }
}
