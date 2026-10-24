import SwiftUI

/// Layout F: Business and Branch with a number tag and the status, a Waffi and a Business logo overlapping, and a three-node route.
/// Follows the phone language (English or Arabic, mirrored), unlike the bilingual A to C.
struct PagerRouteLayout: View {
    let attributes: PagerActivityAttributes
    let state: PagerState
    let palette: PagerPalette
    @Environment(\.locale) private var locale

    private var ready: Bool { state != .waiting }
    private var transparent: Bool { attributes.style.background == .transparent }

    var body: some View {
        let arabic = locale.isArabic
        let name = attributes.branchName.isEmpty ? attributes.businessName : "\(attributes.businessName) · \(attributes.branchName)"
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 8) {
                        Text(verbatim: "\(arabic ? "رقم" : "No.") \(attributes.number)")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(transparent ? Color.black : Color.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(palette.ink, in: RoundedRectangle(cornerRadius: 7))
                        Text(attributes.style.wording.words(for: state).text(arabic: arabic))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(state == .ready ? palette.accent : palette.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                Spacer(minLength: 0)
                // The Waffi mark at the far trailing edge, the Business logo in front of it on its leading side.
                ZStack(alignment: .trailing) {
                    WaffiMark(size: 40, round: true).padding(.top, 4)
                    PagerLogoView(businessName: attributes.businessName, size: 48, tile: palette.brand, glyph: palette.onBrand, round: true)
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 3))
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                        .padding(.trailing, 30)
                }
                .frame(width: 78, height: 48)
            }
            HStack(spacing: 0) {
                node(filled: true, ring: false) { Image(systemName: "checkmark") }
                line(solid: true)
                node(filled: ready, ring: !ready) { Image(systemName: "cup.and.saucer.fill") }
                line(solid: ready)
                node(filled: ready, ring: false) { Image(systemName: "bag.fill") }
            }
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func node<Icon: View>(filled: Bool, ring: Bool, @ViewBuilder icon: () -> Icon) -> some View {
        let color = state == .ended ? palette.secondary : palette.brand
        return ZStack {
            if filled {
                Circle().fill(color)
            } else {
                Circle().strokeBorder(ring ? palette.accent : palette.ink.opacity(0.25), lineWidth: ring ? 3 : 2)
            }
            icon()
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(filled ? palette.onBrand : ring ? palette.accent : palette.ink.opacity(0.4))
        }
        .frame(width: 30, height: 30)
    }

    private func line(solid: Bool) -> some View {
        Line()
            .stroke(solid ? palette.brand : palette.ink.opacity(0.25), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: solid ? [] : [5, 5]))
            .frame(height: 4)
            .padding(.horizontal, 4)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { $0.move(to: CGPoint(x: rect.minX, y: rect.midY)); $0.addLine(to: CGPoint(x: rect.maxX, y: rect.midY)) }
        }
    }
}
