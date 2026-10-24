import SwiftUI

/// The app's tabs, in the website sidebar's order. `visible(for:features:)` follows `apps/web/src/app/layouts/Sidebar.tsx`.
enum AppTab: String, CaseIterable, Identifiable {
    case overview, earn, customers, campaigns, pager

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .overview: "Overview"
        case .earn: "Earn & redeem"
        case .customers: "Customers"
        case .campaigns: "Messages"
        case .pager: "Pager"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "chart.line.uptrend.xyaxis"
        case .earn: "qrcode.viewfinder"
        case .customers: "person.2"
        case .campaigns: "megaphone"
        case .pager: "bell"
        }
    }

    /// The tabs this person sees. `features` is `GET /api/addons`: a tab behind a Feature switch that is off is left out, with no upgrade hint.
    static func visible(for user: AppAccount.User, features: [String: Bool]) -> [AppTab] {
        let manager = user.role == "owner" || user.role == "manager"
        func may(_ permission: String) -> Bool { user.may(permission) }
        return allCases.filter { tab in
            switch tab {
            case .overview: manager
            case .earn: may("cards.view") || may("loyalty.earn") || may("loyalty.redeem")  // canLookupCards
            case .customers: may("customers.view")
            case .campaigns: may("engagement.manage") && features["campaigns"] == true
            case .pager: features["pager"] == true
            }
        }
    }
}
