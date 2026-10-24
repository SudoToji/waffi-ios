import SwiftUI

/// `CUSTOMER_SORTS`: the website's "Sort customers" choices.
enum CustomerSort: String, CaseIterable, Identifiable {
    case newest, name, visits, tier
    case giftsEarned = "gifts_earned"
    case lastVisit = "last_visit"

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .newest: "Newest first"
        case .name: "Name"
        case .visits: "Most visit days"
        case .tier: "Highest tier"
        case .giftsEarned: "Most gifts earned"
        case .lastVisit: "Latest visit"
        }
    }
}

/// The website's Customer tier filter: All tiers, Loyal with no tier, Quiet members, or one tier.
enum TierFilter: Hashable {
    case all, loyalNoTier, quiet
    case tier(String)
}

/// Everything that decides which Customers the list asks for.
struct CustomerQuery: Equatable {
    var search = ""
    var tier = TierFilter.all
    var sort = CustomerSort.newest
    /// `""` is All; otherwise a Branch id, `online` or `none`.
    var joining = ""
}
