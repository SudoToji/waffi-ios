import SwiftUI

/// Layout C: logo, name and Branch, a big thin number and a three-step track (received, the work, ready).
struct PagerTrackLayout: View {
    let attributes: PagerActivityAttributes
    let state: PagerState
    let palette: PagerPalette

    /// The step the order is at: 1 while waiting, 2 (the last) when ready or ended.
    private var reached: Int { state == .waiting ? 1 : 2 }

    /// The first label sits at the left end of the track, the last at the right, the middle one in the middle.
    private func edge(_ index: Int) -> HorizontalAlignment {
        index == 0 ? .leading : index == 1 ? .center : .trailing
    }

    var body: some View {
        let wording = attributes.style.wording
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                PagerLogoView(businessName: attributes.businessName, size: 40, tile: palette.brand, glyph: palette.onBrand)
                VStack(alignment: .leading, spacing: 2) {
                    Text(attributes.businessName).font(.headline).foregroundStyle(palette.ink).lineLimit(1)
                    HStack(spacing: 5) {
                        if !attributes.branchName.isEmpty {
                            Text(attributes.branchName).font(.caption).foregroundStyle(palette.secondary).lineLimit(1)
                            Text(verbatim: "·").font(.caption).foregroundStyle(palette.secondary)
                        }
                        PagerWaffiTag(palette: palette)
                    }
                }
                Spacer(minLength: 8)
                Text(attributes.number)
                    .font(.system(size: 40, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(palette.ink)
            }
            PagerTrack(reached: reached, current: state == .waiting, color: palette.status(state), off: palette.ink.opacity(0.25))
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(wording.trackSteps.enumerated()), id: \.offset) { index, step in
                    VStack(alignment: edge(index), spacing: 0) {
                        Text(step.en)
                        Text(step.ar)
                    }
                    .font(.caption2.weight(index == reached ? .bold : .regular))
                    .foregroundStyle(index == reached ? palette.status(state) : palette.secondary)
                    .frame(maxWidth: .infinity, alignment: Alignment(horizontal: edge(index), vertical: .top))
                }
            }
            if state == .ready {
                PagerStatusLine(words: wording.words(for: .ready), color: palette.status(state), font: .footnote.weight(.bold))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Three dots joined by lines: the ones before `reached` done, the one at `reached` big (a ring while `current`, solid when finished).
private struct PagerTrack: View {
    let reached: Int
    let current: Bool
    let color: Color
    let off: Color

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                if index > 0 {
                    (index <= reached ? color : off).frame(height: 4)
                }
                dot(index)
            }
        }
        .frame(height: 20)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func dot(_ index: Int) -> some View {
        if index == reached && current {
            Circle().strokeBorder(color, lineWidth: 4).frame(width: 20, height: 20)
        } else if index == reached {
            Circle().fill(color).frame(width: 20, height: 20)
        } else {
            Circle().fill(index < reached ? color : off).frame(width: 12, height: 12)
        }
    }
}
