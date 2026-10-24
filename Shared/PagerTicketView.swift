import SwiftUI

/// The ticket screen, in the app and the App Clip: the Business logo (or the Waffi mark), name and Branch, the number on a card with
/// its status, a three-step track, a hint, and "Powered by Waffi" fixed at the bottom on the leading side. Always dark. Read again every
/// 5 seconds while the app is in the foreground.
struct PagerTicketView: View {
    let model: PagerTicketModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.layoutDirection) private var layoutDirection
    @ScaledMetric private var numberSize = 112.0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                switch model.phase {
                case .loading:
                    ProgressView().padding(.top, 160)
                case .open(let ticket):
                    open(ticket)
                case .ended:
                    Label("This ticket has ended", systemImage: "checkmark.circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.secondary)
                        .padding(.top, 160)
                }
                if model.connectionLost && !model.isEnded {
                    Text("Connection lost. Trying again…").font(.footnote).foregroundStyle(Palette.secondary).padding(.top, 16)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) { poweredBy }
        .background(Palette.ground.ignoresSafeArea())
        .foregroundStyle(Palette.text)
        .preferredColorScheme(.dark)
        // Restarts when the app comes back to the foreground, and stops in the background.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                await model.refresh()
                if model.isEnded { return }
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    private func open(_ ticket: PagerTicket) -> some View {
        let ready = ticket.state != .waiting
        return VStack(spacing: 0) {
            logo(ticket.businessName).padding(.top, 20)
            Text(ticket.businessName).font(.title2.bold()).padding(.top, 14)
            if !ticket.branchName.isEmpty {
                Label(ticket.branchName, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondary)
                    .padding(.top, 4)
            }
            numberCard(ticket, ready: ready).padding(.top, 28)
            track(ready: ready).padding(.top, 22)
            hint(ready: ready).padding(.top, 22)
            if model.liveActivityOff {
                Text("Live Activities are off for Waffi, so your order will not show on the lock screen. Keep this screen open, or turn them on in Settings.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondary)
                    .padding(.top, 16)
            }
        }
    }

    /// The Business logo, or the Waffi mark when the Business has none.
    @ViewBuilder private func logo(_ businessName: String) -> some View {
        if let image = PagerLogo.image(forBusiness: businessName) {
            Image(uiImage: image).resizable().scaledToFill()
                .frame(width: 104, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Palette.border))
                .accessibilityHidden(true)
        } else {
            WaffiMark(size: 104)
        }
    }

    private func numberCard(_ ticket: PagerTicket, ready: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return VStack(spacing: 6) {
            Text("Your order number")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ready ? Palette.readyLabel : Palette.secondary)
            Text(ticket.number)
                .font(.system(size: numberSize, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundStyle(.white)
                .environment(\.layoutDirection, .leftToRight)
            Label(ready ? "Ready, collect it at the counter" : "Preparing your order", systemImage: ready ? "checkmark" : "clock")
                .font(.subheadline.bold())
                .foregroundStyle(ready ? Palette.readyPillText : Palette.amber)
                .padding(.vertical, 9)
                .padding(.horizontal, 14)
                .background(ready ? Color.white : Palette.amberPill, in: Capsule())
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 22, leading: 20, bottom: 20, trailing: 20))
        .background(ready ? Palette.readyCard : Palette.card, in: shape)
        .overlay(shape.strokeBorder(ready ? Palette.readyBorder : Palette.border))
    }

    /// Received, Preparing, Ready: the steps done so far filled in the status colour.
    private func track(ready: Bool) -> some View {
        let steps: [LocalizedStringKey] = ["Received", "Preparing", "Ready"]
        let current = ready ? 2 : 1
        let tone = ready ? Palette.green : Palette.amber
        return HStack(alignment: .top, spacing: 8) {
            ForEach(steps.indices, id: \.self) { i in
                VStack(spacing: 8) {
                    Capsule().fill(i <= current ? tone : Palette.border).frame(height: 6)
                    Text(steps[i])
                        .font(.caption.weight(i == current ? .bold : .medium))
                        .foregroundStyle(i == current ? tone : i < current ? Palette.muted : Palette.faint)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true) // the status on the card says the same
    }

    private func hint(ready: Bool) -> some View {
        Label {
            Text(ready ? "Show this screen at the counter." : "Keep your sound on. We will alert you when your order is ready.")
        } icon: {
            Image(systemName: "speaker.wave.2")
        }
        .font(.footnote)
        .foregroundStyle(Palette.muted)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// English reads "Powered by", the mark, "Waffi"; Arabic reads "بدعم من وافي" and then the mark.
    private var poweredBy: some View {
        let brand = Text("Waffi").bold().foregroundStyle(Palette.brandText)
        return HStack(spacing: 7) {
            Text("Powered by")
            if layoutDirection == .rightToLeft {
                brand
                WaffiMark(size: 18)
            } else {
                WaffiMark(size: 18)
                brand
            }
        }
        .font(.caption)
        .foregroundStyle(Palette.secondary)
        .accessibilityElement(children: .combine)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Palette.ground)
    }
}

/// The ticket screen's fixed dark colours (design canvas "Customer ticket screen").
private enum Palette {
    static let ground = Color(hex: 0x121917)
    static let card = Color(hex: 0x1C2421)
    static let border = Color(hex: 0x2C3631)
    static let text = Color(hex: 0xF2F4F1)
    static let secondary = Color(hex: 0x9AA39D)
    static let muted = Color(hex: 0xB9C1BC)
    static let faint = Color(hex: 0x6F7A74)
    static let brandText = Color(hex: 0xDCE2DE)
    static let amber = Color(hex: 0xF5A35C)
    static let amberPill = Color(hex: 0x3A2A1C)
    static let green = Color(hex: 0x86C49F)
    static let readyCard = Color(hex: 0x2E5A43)
    static let readyBorder = Color(hex: 0x3F7559)
    static let readyLabel = Color(hex: 0xCFE3D6)
    static let readyPillText = Color(hex: 0x1F3F2E)
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
