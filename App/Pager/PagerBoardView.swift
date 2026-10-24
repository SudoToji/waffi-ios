import SwiftUI

/// One Branch's board: the number pad on top, then the Waiting and Ready lists, read again every 5 seconds.
struct PagerBoardView: View {
    @Bindable var model: StaffPagerModel
    let businessName: String
    @Environment(\.scenePhase) private var scenePhase
    @State private var number = ""
    /// `waiting` or `ready`.
    @State private var tab = "waiting"

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                PagerNumberPad(number: $number, busy: model.busy) {
                    Task {
                        if await model.create(number: number.trimmingCharacters(in: .whitespaces).uppercased()) { number = "" }
                    }
                }
                errorLine
                if model.ticketsLoaded {
                    PagerTabs(
                        selection: $tab,
                        waiting: model.tickets.filter { $0.state == "waiting" }.count,
                        ready: model.tickets.filter { $0.state == "ready" }.count
                    )
                    PagerTicketList(model: model, state: tab)
                } else if model.listError == nil {
                    ProgressView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
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
            PagerQRView(ticket: ticket, place: "\(businessName) · \(model.branch?.name ?? "")")
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
