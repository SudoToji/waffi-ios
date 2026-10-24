import SwiftUI

/// One state's tickets as cards, oldest first (the order the API gives).
struct PagerTicketList: View {
    let model: StaffPagerModel
    /// `waiting` or `ready`.
    let state: String

    private var tickets: [StaffTicket] { model.tickets.filter { $0.state == state } }
    private var emptyText: LocalizedStringKey { state == "waiting" ? "No orders waiting." : "No orders ready." }

    var body: some View {
        if tickets.isEmpty {
            Text(emptyText)
                .foregroundStyle(Theme.secondaryText)
                .padding(.top, 8)
        } else {
            VStack(spacing: 8) {
                ForEach(tickets) { ticket in
                    PagerTicketRow(model: model, ticket: ticket)
                }
            }
        }
    }
}

private struct PagerTicketRow: View {
    let model: StaffPagerModel
    let ticket: StaffTicket
    private var isWaiting: Bool { ticket.state == "waiting" }
    private var actionTitle: LocalizedStringKey { isWaiting ? "Ready" : "Done" }
    private var actionLabel: LocalizedStringKey { isWaiting ? "Mark order \(ticket.number) ready" : "Mark order \(ticket.number) done" }

    var body: some View {
        HStack(spacing: 12) {
            // Tapping the number side shows the QR again.
            Button {
                model.shown = ticket
            } label: {
                HStack(spacing: 12) {
                    Text(ticket.number)
                        .font(.system(.title, design: .rounded, weight: .heavy))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(minWidth: 48, alignment: .leading)
                        .environment(\.layoutDirection, .leftToRight)
                    VStack(alignment: .leading, spacing: 2) {
                        // The wait is shown to the minute, so a slow tick is enough.
                        TimelineView(.periodic(from: .now, by: 30)) { context in
                            // A phone clock a little behind the server's must not read "in 3 sec.".
                            let since = min(isWaiting ? ticket.createdAt : ticket.readyAt ?? ticket.createdAt, context.date)
                            Text(since.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))
                        }
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                        if ticket.scanned {
                            Text("Following on their phone").foregroundStyle(Theme.accent)
                        } else {
                            Text("Not scanned yet").foregroundStyle(Theme.warning)
                        }
                    }
                    .font(.footnote.weight(.semibold))
                    Spacer(minLength: 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Show the QR for order \(ticket.number)")

            Button {
                Task { if isWaiting { await model.ready(ticket) } else { await model.done(ticket) } }
            } label: {
                Text(actionTitle)
            }
            .buttonStyle(.waffiCompact)
            .disabled(model.busy)
            .accessibilityLabel(actionLabel)
        }
        .padding(.vertical, 10)
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .contextMenu {
            if isWaiting {
                Button("Done", systemImage: "checkmark") { Task { await model.done(ticket) } }
            }
        }
    }
}
