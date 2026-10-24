import SwiftUI

/// One Branch's board: the number pad on top, then the Waiting and Ready lists, read again every 5 seconds.
struct PagerBoardView: View {
    @Bindable var model: StaffPagerModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var number = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Type the order number, show the QR to your customer, and tap Ready when the order is done.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if model.branches.count > 1, let branch = model.branch {
                    Button("Serving at \(branch.name)") { model.changeBranch() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                PagerNumberPad(number: $number, busy: model.busy) {
                    Task {
                        if await model.create(number: number.trimmingCharacters(in: .whitespaces).uppercased()) { number = "" }
                    }
                }
                errorLine
                if model.ticketsLoaded {
                    ForEach(["waiting", "ready"], id: \.self) { state in
                        PagerTicketList(model: model, state: state)
                    }
                } else if model.listError == nil {
                    ProgressView()
                }
            }
            .padding(16)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        // Reads again every 5 seconds while the app is in the foreground; restarts when it comes back.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                await model.refresh()
                try? await Task.sleep(for: .seconds(5))
            }
        }
        .fullScreenCover(item: $model.shown) { ticket in
            PagerQRView(ticket: ticket)
        }
    }

    @ViewBuilder private var errorLine: some View {
        if let error = model.actionError ?? model.listError {
            Group {
                if error.code == "PAGER_NUMBER_TAKEN" {
                    Text("Order \(model.attempt) is already waiting. Use a different number or finish that ticket first.")
                } else {
                    Text(error.message)
                }
            }
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
        }
    }
}
