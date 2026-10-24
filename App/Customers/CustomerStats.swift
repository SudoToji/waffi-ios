import SwiftUI

/// The seven figures of the website's Customer drawer as tiles, then the rest of what is known about the Customer.
struct CustomerStats: View {
    let customer: Customer
    let figures: CustomerFigures?
    let error: ApiError?
    /// Owners and Managers see who set the tier and when.
    let showTierRecord: Bool
    let retry: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 3)
    }

    var body: some View {
        if let figures {
            VStack(spacing: 10) {
                LazyVGrid(columns: columns, spacing: 10) {
                    tile(CustomerFormat.ltr("\(figures.visitDays) / 30"), "Visit days in the last 30 days")
                    tile(figures.totalVisitDays.formatted(), "Total visit days")
                    lastVisitTile(figures.lastVisit)
                    tile(figures.giftsEarned.formatted(), "Gifts earned")
                    tile(figures.giftsRedeemed.formatted(), "Gifts redeemed")
                    tile(figures.giftsWaiting.formatted(), "Gifts waiting")
                }
                details(figures)
            }
        } else if let error {
            VStack(spacing: 12) {
                Text(error.message).multilineTextAlignment(.center).foregroundStyle(Theme.text)
                Button("Retry", action: retry).buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private func tile(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: value)
                .font(.title2.weight(.heavy))
                .monospacedDigit()
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label).font(.caption).foregroundStyle(Theme.secondaryText).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func lastVisitTile(_ date: Date?) -> some View {
        if let text = CustomerFormat.lastVisit(date) {
            tile(text, "Last visit")
        } else {
            tile(String(localized: "No visit yet"), "Last visit")
        }
    }

    private func details(_ figures: CustomerFigures) -> some View {
        let rows = detailRows(figures)
        return VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                if index > 0 { Rectangle().fill(Theme.border).frame(height: 1 / 3) }
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(rows[index].label).font(.subheadline).foregroundStyle(Theme.secondaryText)
                    Spacer(minLength: 8)
                    Text(verbatim: rows[index].value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityElement(children: .combine)
            }
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private struct DetailRow {
        let label: LocalizedStringKey
        let value: String
    }

    private func detailRows(_ figures: CustomerFigures) -> [DetailRow] {
        var rows = [DetailRow(label: "Customer since", value: CustomerFormat.day(figures.customerSince))]
        if let text = customer.birthday, let birthday = CustomerFormat.birthday(text) {
            rows.append(DetailRow(label: "Birthday", value: birthday.formatted(date: .abbreviated, time: .omitted)))
        }
        rows.append(
            DetailRow(
                label: "Preferred language",
                value: customer.preferredLocale == "ar" ? String(localized: "Arabic") : String(localized: "English")))
        if showTierRecord, let record = figures.tierRecord {
            let who = record.setBy?.email ?? "Waffi"
            rows.append(
                DetailRow(label: "Customer tier", value: String(localized: "Tier set by \(who) on \(CustomerFormat.day(record.setAt))")))
        }
        return rows
    }
}
