import SwiftUI

/// The Customers matching the search field; a Customer with several Cards opens a choice of Cards.
struct SearchResults: View {
    let model: EarnModel
    let query: String
    @State private var expanded: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = model.resultsError {
                Text(error.message).font(.subheadline).foregroundStyle(Theme.warning)
                Button("Retry") { Task { await model.search(query) } }.buttonStyle(.waffiTinted)
            } else if model.results.isEmpty {
                if model.resultsLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(24)
                } else {
                    Text("No Customers match. Try another name or phone.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(24)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(model.results) { customer in
                        if customer.id != model.results.first?.id { Rectangle().fill(Theme.border).frame(height: 1 / 3) }
                        row(customer)
                    }
                }
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
                if model.nextCursor != nil {
                    Button("Show more") { Task { await model.loadMore(query) } }
                        .buttonStyle(.waffiTinted)
                        .disabled(model.resultsLoading)
                }
            }
        }
    }

    @ViewBuilder private func row(_ customer: DirectoryCustomer) -> some View {
        let single = customer.cards.count == 1 ? customer.cards[0] : nil
        Button {
            if let single {
                Task { await model.lookup(single.manualCode) }
            } else if !customer.cards.isEmpty {
                expanded = expanded == customer.id ? nil : customer.id
            }
        } label: {
            HStack(spacing: 12) {
                Avatar(name: customer.name, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: customer.name).font(.body.weight(.bold)).foregroundStyle(Theme.text)
                    subtitle(customer, single: single)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if customer.cards.count > 1 {
                    Image(systemName: expanded == customer.id ? "chevron.down" : "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(customer.cards.isEmpty || model.searching)
        if expanded == customer.id {
            VStack(spacing: 8) {
                ForEach(customer.cards) { entry in
                    Button { Task { await model.lookup(entry.manualCode) } } label: {
                        HStack {
                            Text(verbatim: entry.manualCode).monospacedDigit().environment(\.layoutDirection, .leftToRight)
                            Spacer()
                            Text(verbatim: "\(entry.balance.formatted(.number)) \(entry.unit)")
                        }
                    }
                    .buttonStyle(.waffiTinted)
                    .disabled(model.searching)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder private func subtitle(_ customer: DirectoryCustomer, single: DirectoryCustomer.CardEntry?) -> some View {
        Group {
            if let single {
                Text(verbatim: "\(single.manualCode) · \(single.balance.formatted(.number)) \(single.unit)")
            } else if customer.cards.isEmpty {
                Text("No Card available")
            } else {
                Text("Choose from \(customer.cards.count) Cards")
            }
        }
        .font(.footnote)
        .foregroundStyle(Theme.secondaryText)
    }
}
