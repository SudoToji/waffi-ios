import SwiftUI

/// One Customer of the list: initials, name, contact, Customer Tier and last visit.
struct CustomerRow: View {
    let customer: Customer
    let showTier: Bool

    var body: some View {
        HStack(spacing: 12) {
            Avatar(name: customer.name, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(verbatim: customer.name).font(.body.weight(.bold)).foregroundStyle(Theme.text)
                    LoyaltyMarkBadge(mark: customer.loyaltyMark)
                }
                Text(verbatim: CustomerFormat.ltr(customer.contactLine))
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                if customer.isQuiet {
                    Text("No visit for 10 days").font(.caption.weight(.semibold)).foregroundStyle(Theme.warning)
                }
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                if showTier, let tier = customer.customerTier { TierBadge(tier: tier) }
                if let visit = CustomerFormat.lastVisit(customer.lastVisit) {
                    Text(verbatim: visit).font(.caption).foregroundStyle(Theme.secondaryText)
                }
            }
            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 44)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
