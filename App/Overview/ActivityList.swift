import SwiftUI

/// "Recent activity": the newest Transactions as hairline-separated rows in a white card.
struct ActivityList: View {
    /// Nil while loading.
    let rows: [ActivityRow]?
    let failed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent activity")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                if let rows {
                    if rows.isEmpty {
                        note("No activity yet.")
                    }
                    ForEach(rows) { row in
                        if row.id != rows.first?.id { Rectangle().fill(Theme.border).frame(height: 1 / 3) }
                        ActivityRowView(row: row)
                    }
                } else if failed {
                    note("Could not load recent activity. Pull down to try again.")
                } else {
                    ProgressView().frame(maxWidth: .infinity).padding(24)
                }
            }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private func note(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Theme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(24)
    }
}

private struct ActivityRowView: View {
    let row: ActivityRow

    var body: some View {
        HStack(spacing: 12) {
            Text(verbatim: String(row.customerName.prefix(1)))
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 40, height: 40)
                .background(Theme.accentTint, in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: row.customerName).font(.body.weight(.bold)).foregroundStyle(Theme.text)
                Text(verbatim: row.subtitle).font(.footnote).foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(row.amount, format: .number.sign(strategy: .always(includingZero: false)))
                    .font(.body.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(Theme.text)
                Text(row.createdAt, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(row.customerName), \(row.subtitle)"))
        .accessibilityValue(
            Text(verbatim: "\(row.amount.formatted(.number.sign(strategy: .always(includingZero: false)))) \(row.unit), \(row.createdAt.formatted(.relative(presentation: .numeric, unitsStyle: .wide)))"))
    }
}
