import SwiftUI

/// The small WAFFI tag every card carries. `color` overrides the palette's where the tag sits on a fill.
struct PagerWaffiTag: View {
    let palette: PagerPalette
    var color: Color?

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color ?? palette.accent).frame(width: 5, height: 5)
            Text(verbatim: "WAFFI")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(color ?? palette.secondary)
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

/// The status line: English and Arabic at the two ends.
struct PagerStatusLine: View {
    let words: PagerWords
    let color: Color
    var font = Font.subheadline.weight(.semibold)

    var body: some View {
        HStack {
            Text(words.en)
            Spacer(minLength: 8)
            Text(words.ar)
        }
        .font(font)
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}
