import SwiftUI

/// "Recent activity": the Customer's latest 10 Transactions across their Cards, newest first, each with its Branch.
struct CustomerHistorySection: View {
    let history: [HistoryRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent activity")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                if history.isEmpty {
                    Text("No activity yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(24)
                }
                ForEach(history) { row in
                    if row.id != history.first?.id { Rectangle().fill(Theme.border).frame(height: 1 / 3) }
                    HistoryRowView(row: row)
                }
            }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

private struct HistoryRowView: View {
    let row: HistoryRow

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: row.systemImage)
                .font(.body.weight(.bold))
                .foregroundStyle(row.type == "redeem" ? Theme.warning : Theme.accent)
                .frame(width: 40, height: 40)
                .background(row.type == "redeem" ? Theme.warning.opacity(0.15) : Theme.accentTint, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: row.title).font(.body.weight(.bold)).foregroundStyle(Theme.text)
                Text(verbatim: subtitle).font(.footnote).foregroundStyle(Theme.secondaryText)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Text(row.amount, format: .number.sign(strategy: .always(includingZero: false)))
                .font(.body.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    /// "17 Oct, 18:02 · Maadi", or "Business-wide" for a row with no Branch.
    private var subtitle: String {
        "\(CustomerFormat.dayAndTime(row.createdAt)) \u{00B7} \(row.branchName ?? String(localized: "Business-wide"))"
    }
}
