import SwiftUI

/// One state's tickets, oldest first (the order the API gives).
struct PagerTicketList: View {
    let model: StaffPagerModel
    /// `waiting` or `ready`.
    let state: String

    private var tickets: [StaffTicket] { model.tickets.filter { $0.state == state } }
    private var isWaiting: Bool { state == "waiting" }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(isWaiting ? "Waiting orders" : "Ready orders").font(.headline)
                Text(tickets.count, format: .number)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            if tickets.isEmpty {
                Text(isWaiting ? "No orders waiting." : "No orders ready.").foregroundStyle(.secondary)
            } else {
                ForEach(tickets) { ticket in
                    PagerTicketRow(model: model, ticket: ticket)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct PagerTicketRow: View {
    let model: StaffPagerModel
    let ticket: StaffTicket
    private var isWaiting: Bool { ticket.state == "waiting" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(ticket.number)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .environment(\.layoutDirection, .leftToRight)
                // The wait is shown to the minute, so a slow tick is enough.
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    let time = Self.elapsed(since: isWaiting ? ticket.createdAt : ticket.readyAt ?? ticket.createdAt, now: context.date)
                    Group {
                        if isWaiting { Text("Waiting \(time)") } else { Text("Ready \(time)") }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                if !ticket.scanned {
                    Text("Not scanned yet").font(.caption.weight(.semibold)).foregroundStyle(.orange)
                }
            }
            ViewThatFits {
                HStack { actions }
                VStack(alignment: .leading) { actions }
            }
            .controlSize(.small)
            .disabled(model.busy)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private var actions: some View {
        if isWaiting {
            Button {
                Task { await model.ready(ticket) }
            } label: {
                Label("Ready", systemImage: "bell.badge")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Mark order \(ticket.number) ready")
        }
        Button {
            Task { await model.done(ticket) }
        } label: {
            Label("Done", systemImage: "checkmark")
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Mark order \(ticket.number) done")
        Button {
            model.shown = ticket
        } label: {
            Label("Show QR", systemImage: "qrcode")
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Show the QR for order \(ticket.number)")
    }

    /// "4 min", "1 hr, 5 min" or "under 1 min": the Pager only needs the wait to the nearest minute.
    private static func elapsed(since date: Date, now: Date) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(date)) / 60)
        if minutes < 1 { return String(localized: "under 1 min") }
        return Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}
