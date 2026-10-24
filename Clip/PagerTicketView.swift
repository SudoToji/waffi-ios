import SwiftUI

/// The ticket screen: logo, Business, Branch, number and status, read again every 5 seconds while the Clip is in the foreground.
struct PagerTicketView: View {
    let model: PagerTicketModel
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric private var numberSize = 72.0

    var body: some View {
        VStack(spacing: 20) {
            switch model.phase {
            case .loading:
                ProgressView()
            case .open(let ticket):
                open(ticket)
            case .ended:
                Label("This ticket has ended", systemImage: PagerState.ended.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PagerState.ended.color)
            }
            if model.connectionLost && !model.isEnded {
                Text("Connection lost. Trying again…").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Restarts when the Clip comes back to the foreground, and stops in the background.
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
        VStack(spacing: 20) {
            PagerLogoView(businessName: ticket.businessName, size: 88)
            VStack(spacing: 4) {
                Text(ticket.businessName).font(.title2.weight(.semibold))
                if !ticket.branchName.isEmpty {
                    Text(ticket.branchName).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            VStack(spacing: 4) {
                Text("Your order number").font(.subheadline).foregroundStyle(.secondary)
                Text(ticket.number)
                    .font(.system(size: numberSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Label(ticket.state.message, systemImage: ticket.state.symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(ticket.state.color)
            Text("Turn off silent mode so you hear it when your order is ready.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if model.liveActivityOff {
                Text("Live Activities are off for Waffi, so your order will not show on the lock screen. Keep this screen open, or turn them on in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
