import SwiftUI

/// The website's names for the audiences (`campaigns.audiences.*`, `campaigns.rules.*`).
enum AudienceLabel {
    static func name(_ audience: String) -> LocalizedStringKey {
        switch audience {
        case "all": "All active-card customers"
        case "inactive": "Inactive customers"
        case "near_reward": "Near a reward"
        case "tiers": "Selected tiers"
        case "birthday_today": "Birthday today"
        case "birthday_month": "Birthday this month"
        case "birthday_range": "Birthday on a day or between two days"
        case "customer": "One customer"
        case "joining_branch": "Joined at a Branch"
        default: ""
        }
    }

    /// What the audience means, as the website explains it under the choice.
    static func rule(_ audience: String, days: Int) -> Text {
        switch audience {
        case "all": Text("Customers with at least one active loyalty card.")
        case "inactive": Text("Customers with an active card and no activity in the last \(days) days.")
        case "near_reward":
            Text("Customers at 80% or more of an available reward target, who have not reached it yet. Used one-time rewards and locked membership rewards are excluded.")
        case "tiers": Text("Only customers in the selected tiers, including owner overrides.")
        case "birthday_today":
            Text("Customers with an active card whose birthday is today (Cairo time). Checked again at the moment of sending, so nothing goes out after midnight.")
        case "birthday_month":
            Text("Customers with an active card whose birthday is in the current month (Cairo time). Checked again at the moment of sending.")
        case "birthday_range":
            Text("Customers with an active card whose birthday falls on or between the two days you choose, whatever the year. Pick the same day twice for a single day. Checked again at the moment of sending.")
        case "customer": Text("Only the selected customer card. Marketing consent is still required.")
        case "joining_branch":
            Text("Customers who signed up at the chosen Branch. Customers who joined online, or whose Branch is not recorded, are never included. If the Branch closes or is Locked, the campaign reaches nobody until it works again.")
        default: Text(verbatim: "")
        }
    }

    /// A short name for a saved message's audience chip: the tiers, the Branch or the Customer when it names them.
    static func chip(_ campaign: Campaign, tiers: [CustomerTier], branches: [StaffBranch]) -> String {
        switch campaign.audience {
        case "tiers":
            let names = (campaign.tierIds ?? []).compactMap { id in tiers.first { $0.id == id }?.displayName }
            if !names.isEmpty { return names.joined(separator: ", ") }
        case "joining_branch":
            if let branch = branches.first(where: { $0.id == campaign.branchId }) { return branch.name }
        case "customer":
            if let code = campaign.customerCode { return String(localized: "One customer") + " · " + code }
        case "inactive":
            return String(localized: "\(campaign.inactiveDays) days without activity")
        default: break
        }
        return String(localized: String.LocalizationValue(fallbackKey(campaign.audience)))
    }

    private static func fallbackKey(_ audience: String) -> String {
        switch audience {
        case "all": "All active-card customers"
        case "inactive": "Inactive customers"
        case "near_reward": "Near a reward"
        case "tiers": "Selected tiers"
        case "birthday_today": "Birthday today"
        case "birthday_month": "Birthday this month"
        case "birthday_range": "Birthday on a day or between two days"
        case "customer": "One customer"
        default: "Joined at a Branch"
        }
    }
}
