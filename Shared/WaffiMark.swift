import SwiftUI

/// The Waffi logo mark: the "w" tick and its ember dot on a forest-green rounded tile. Drawn in the 120 x 120 box of the website's logo.
struct WaffiMark: View {
    var size: CGFloat = 32

    var body: some View {
        let scale = size / 120
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(Color(red: 47 / 255, green: 86 / 255, blue: 64 / 255))
            Tick()
                .stroke(
                    Color(red: 236 / 255, green: 235 / 255, blue: 225 / 255),
                    style: StrokeStyle(lineWidth: 11 * scale, lineCap: .round, lineJoin: .round))
            Circle()
                .fill(Color(red: 242 / 255, green: 106 / 255, blue: 75 / 255)) // the ember accent
                .frame(width: 17 * scale, height: 17 * scale)
                .offset(x: (94 - 8.5) * scale, y: (37 + 4 - 8.5) * scale)
        }
        .frame(width: size, height: size)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    /// `M24 46 L39 78 L54 52 L69 78 L94 37`, moved down 4.
    private struct Tick: Shape {
        func path(in rect: CGRect) -> Path {
            let scale = rect.width / 120
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * scale, y: rect.minY + (y + 4) * scale) }
            var path = Path()
            path.move(to: point(24, 46))
            path.addLine(to: point(39, 78))
            path.addLine(to: point(54, 52))
            path.addLine(to: point(69, 78))
            path.addLine(to: point(94, 37))
            return path
        }
    }
}
