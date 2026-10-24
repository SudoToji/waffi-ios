import SwiftUI

/// A pager / buzzer: a thin ring of evenly spaced dots with the order number inside. Solid when `filled` (ready).
/// Static on purpose: a Live Activity cannot animate continuously.
struct PagerRing: View {
    var number: String?
    let color: Color
    var filled = false
    var size: CGFloat = 68
    /// The number's colour when the ring is not filled.
    var ink: Color = .primary

    var body: some View {
        ZStack {
            if filled {
                Circle().fill(color)
            } else {
                dots
            }
            if let number {
                Text(number)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(filled ? Color.white : ink)
                    .padding(size * 0.2)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(number == nil)
    }

    private var dots: some View {
        let count = max(8, Int(size / 2.4))
        let dot = max(2, size / 22)
        return ZStack {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: dot, height: dot)
                    .offset(y: -(size - dot) / 2)
                    .rotationEffect(.degrees(Double(index) * 360 / Double(count)))
            }
        }
    }
}
