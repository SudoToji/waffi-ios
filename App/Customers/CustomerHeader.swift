import SwiftUI

/// The top of a Customer's page: initials, name, contact, the tier and the Loyalty Mark, and where they joined.
struct CustomerHeader: View {
    let customer: Customer
    let showTier: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(spacing: 14))
            layout {
                Avatar(name: customer.name, size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: customer.name)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Theme.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: CustomerFormat.ltr(customer.contactLine))
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                    HStack(spacing: 6) {
                        if showTier, let tier = customer.customerTier { TierBadge(tier: tier) }
                        LoyaltyMarkBadge(mark: customer.loyaltyMark)
                    }
                }
                .multilineTextAlignment(.leading)
            }
            Text(verbatim: joinedText).font(.footnote).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    /// "Joined at <Branch>" (marked closed or Locked), "Joined online" or "Joining Branch not recorded".
    private var joinedText: String {
        switch customer.joined {
        case .branch(let name, let status):
            let label =
                status == "closed" ? String(localized: "\(name) (closed)")
                : status == "locked" ? String(localized: "\(name) (Locked)") : name
            return String(localized: "Joined at \(label)")
        case .online: return String(localized: "Joined online")
        case .notRecorded: return String(localized: "Joining Branch not recorded")
        }
    }
}
