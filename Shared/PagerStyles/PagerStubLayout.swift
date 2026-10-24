import SwiftUI

/// Layout B: a ticket whose tear-off stub holds the number. The stub runs to the edge of the card, so there is no outer padding.
struct PagerStubLayout: View {
    let attributes: PagerActivityAttributes
    let state: PagerState
    let palette: PagerPalette

    private var words: PagerWords { attributes.style.wording.words(for: state) }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    PagerLogoView(businessName: attributes.businessName, size: 40, tile: palette.brand, glyph: palette.onBrand)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(attributes.businessName).font(.subheadline.weight(.bold)).foregroundStyle(palette.ink).lineLimit(1)
                        if !attributes.branchName.isEmpty {
                            Text(attributes.branchName).font(.caption).foregroundStyle(palette.secondary).lineLimit(1)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(words.en).font(.subheadline.weight(.bold))
                    Text(words.ar).font(.footnote.weight(.semibold))
                }
                .foregroundStyle(palette.status(state))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            }
            .padding(16)
            Spacer(minLength: 0)
            stub
        }
    }

    private var stub: some View {
        VStack(spacing: 2) {
            Text(verbatim: attributes.style.wording.numberLabel)
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundStyle(stubInk.opacity(0.7))
            Text(attributes.number)
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(stubInk)
            PagerWaffiTag(palette: palette, color: stubInk)
        }
        .padding(.horizontal, 8)
        .frame(width: 108)
        .frame(maxHeight: .infinity)
        .background(stubFill)
        .overlay(alignment: .leading) {
            VerticalLine()
                .stroke(stubInk.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                .frame(width: 2)
        }
    }

    /// Ready: the brand colour. Waiting: a light tint of it. On see-through glass or once ended: neutral glass.
    private var stubFill: Color {
        if state == .ended { return Color.white.opacity(0.12) }
        if state == .ready { return palette.brand }
        return isGlass ? Color.white.opacity(0.12) : PagerColors.color(PagerColors.mix(palette.brandHex, with: "#FFFFFF", 0.6))
    }

    private var stubInk: Color {
        if state == .ended { return palette.ink }
        if state == .ready { return palette.onBrand }
        return isGlass ? palette.ink : PagerColors.onColor(PagerColors.mix(palette.brandHex, with: "#FFFFFF", 0.6))
    }

    private var isGlass: Bool { attributes.style.background == .transparent }
}

private struct VerticalLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}
