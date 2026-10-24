import Foundation

/// A Customer Tier (`CustomerTierView` in waffi `packages/shared`): set by hand on a Customer, not to be confused with a Card Tier.
struct CustomerTier: Decodable, Equatable, Identifiable {
    let id: String
    let name: String
    let nameAr: String?
    let rank: Int

    /// `customerTierName`: the Arabic name on an Arabic phone when there is one.
    var displayName: String {
        if Locale.current.language.languageCode?.identifier == "ar", let nameAr, !nameAr.isEmpty { return nameAr }
        return name
    }
}

/// Who set a Customer's tier and when. The server sends it to Owners and Managers only.
struct TierRecord: Decodable, Equatable {
    struct SetBy: Decodable, Equatable {
        let id: String
        let email: String
    }

    let setAt: Date
    let setBy: SetBy?
}

/// Where a Customer joined: a Branch, online, or not recorded (`JoinedAt`).
enum JoinedAt: Decodable, Equatable {
    case branch(name: String, status: String)
    case online
    case notRecorded

    private enum Keys: String, CodingKey { case kind, name, status }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        switch try container.decode(String.self, forKey: .kind) {
        case "branch":
            self = .branch(
                name: try container.decode(String.self, forKey: .name), status: try container.decode(String.self, forKey: .status))
        case "online": self = .online
        default: self = .notRecorded
        }
    }
}

/// One Card of a Customer as the Customers list sends it (`CustomerCardSummary`).
struct CustomerCard: Decodable, Equatable, Identifiable {
    let id: String
    /// Six digits; what the Card's QR holds.
    let manualCode: String
    let nameEn: String?
    let nameAr: String?
    /// `points`, `stamps`, `attendance` or `tier`.
    let cardType: String
    let points: Double
    let stamps: Double
    let visits: Double
    let status: String
    let availableGifts: Int?

    var isActive: Bool { status == "active" }

    /// The Card Template's name in the phone's language.
    var title: String {
        let arabic = Locale.current.language.languageCode?.identifier == "ar"
        let (first, second) = arabic ? (nameAr, nameEn) : (nameEn, nameAr)
        if let first, !first.isEmpty { return first }
        if let second, !second.isEmpty { return second }
        return String(localized: "Loyalty card")
    }
}

/// A Customer as `GET /api/customers` and `GET /api/customers/:id` answer it (`CustomerView`). The activity fields are the list's own figures.
struct Customer: Decodable, Equatable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    /// `YYYY-MM-DD`.
    let birthday: String?
    /// `en` or `ar`.
    let preferredLocale: String
    let createdAt: Date
    let cardCount: Int
    let marketingConsent: Bool?
    let cards: [CustomerCard]
    let joined: JoinedAt
    let visitDays: Int?
    /// `returning`, `loyal` or nil.
    let loyaltyMark: String?
    let lastVisit: Date?
    let giftsEarned: Int?
    let manualTier: Bool?
    let customerTier: CustomerTier?
    /// The "No visit for 10 days" flag; always false for anyone who may not set tiers.
    let quiet: Bool?
    let hasTierMessagePass: Bool?
    let tierRecord: TierRecord?

    var isQuiet: Bool { quiet == true }
    var activeCards: [CustomerCard] { cards.filter(\.isActive) }

    /// "email · phone", or an em dash.
    var contactLine: String {
        let parts = [email, phone].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? "\u{2014}" : parts.joined(separator: " \u{00B7} ")
    }
}

struct CustomerPage: Decodable {
    let items: [Customer]
    let nextCursor: String?
}

/// `GET /api/customers/joining-branches`: the chip counts over the whole Business.
struct JoiningBranchCounts: Decodable, Equatable {
    struct Entry: Decodable, Equatable, Identifiable {
        let branchId: String
        let name: String
        let count: Int
        var id: String { branchId }
    }

    let branches: [Entry]
    /// Every Branch, open or closed: the chips show only when it is more than one.
    let branchCount: Int
    let online: Int
    let notRecorded: Int
    let total: Int
}

/// Saved Gifts of one Cairo month (`YYYY-MM`).
struct GiftMonth: Decodable, Equatable, Identifiable {
    let month: String
    let earned: Int
    let redeemed: Int
    var id: String { month }
}

/// One of a Customer's latest Transactions across their Cards (`CustomerHistoryRow`).
struct HistoryRow: Decodable, Equatable, Identifiable {
    let id: String
    let createdAt: Date
    /// `earn`, `redeem` or `adjust`.
    let type: String
    let source: String?
    /// Signed: a redeem is negative.
    let amount: Double
    /// Nil for a Business-wide row.
    let branchName: String?

    /// What happened, in the phone's language (the website's `transactionLabelKey`).
    var title: String {
        switch source {
        case "reward_unlock": return String(localized: "Gift saved")
        case "reversal": return String(localized: "Entry undone")
        case "gift_expired": return String(localized: "Gift expired")
        case "import": return String(localized: "Opening balance")
        default: break
        }
        switch type {
        case "earn": return String(localized: "Earned")
        case "redeem": return String(localized: "Redeemed")
        default: return String(localized: "Adjustment")
        }
    }

    var systemImage: String {
        switch source {
        case "reward_unlock", "gift_expired": return "gift"
        case "reversal": return "arrow.uturn.backward"
        default: break
        }
        switch type {
        case "earn": return "plus"
        case "redeem": return "gift"
        default: return "slider.horizontal.3"
        }
    }
}

/// `GET /api/customers/:id/figures`: the seven figures, the gifts graph and the latest 10 Transactions (`CustomerFigures`).
struct CustomerFigures: Decodable, Equatable {
    let id: String
    let visitDays: Int
    let lastVisit: Date?
    let giftsEarned: Int
    let quiet: Bool?
    let tierRecord: TierRecord?
    let totalVisitDays: Int
    let giftsRedeemed: Int
    let giftsWaiting: Int
    let customerSince: Date
    let months: [GiftMonth]
    let joined: JoinedAt
    let history: [HistoryRow]
}

/// Answers of the write routes that send back only the id.
struct IdAnswer: Decodable {
    let id: String
}

/// `POST /api/enrollment/customers/:id/card-link`: the private link's parts. The link is built here and never kept.
struct CardLinkAnswer: Decodable {
    let slug: String
    let token: String
}

struct CardCutOffAnswer: Decodable {
    let cardId: String
}
