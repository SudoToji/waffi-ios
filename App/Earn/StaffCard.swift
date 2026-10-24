import Foundation

/// A Card as `GET /api/loyalty/lookup` answers it (`StaffCard` in waffi `packages/shared`), reduced to what the counter uses.
struct StaffCard: Decodable, Equatable {
    let id: String
    let customerName: String
    /// Six digits; what the Card's QR holds.
    let manualCode: String
    /// `points`, `stamps`, `attendance` or `tier`.
    let cardType: String
    /// What the Balance counts: "stamps", "points", "visits"...
    let unitLabel: String
    let balance: Double
    /// The Card Tier's name (a `tier` Card).
    let tierName: String
    /// The Business's currency (`EGP`).
    let currency: String
    let rewards: [LoyaltyReward]
    let today: CardToday?
    /// `not_connected`, `pending`, `synced` or `retrying` (the Google Wallet pass).
    let walletSync: String?

    var isStamps: Bool { cardType == "stamps" }
    /// Points Cards take the purchase amount; stamps take a count; visits take nothing.
    var takesPurchase: Bool { cardType == "points" || cardType == "tier" }
    var savedGifts: Int { rewards.filter { $0.grantId != nil }.reduce(0) { $0 + $1.availableGifts } }
    var readyRewards: [LoyaltyReward] { rewards.filter(\.eligible) }
    var lockedRewards: [LoyaltyReward] { rewards.filter { !$0.eligible } }

    /// The Reward the Balance is heading for: the nearest Threshold still ahead, else the lowest (Saved Gifts do not count).
    var target: LoyaltyReward? {
        let live = rewards.filter { $0.grantId == nil }.sorted { $0.threshold < $1.threshold }
        return live.first { $0.threshold > balance } ?? live.first
    }
}

/// What this Card already had today (Cairo day), not counting undone Operations.
struct CardToday: Decodable, Equatable {
    let stamps: Int
    let redemptions: Int

    /// The website warns once a Card has this many stamps today, or this many redeemed Rewards.
    static let stampsWarning = 2
    static let redemptionsWarning = 1
}

/// A live Reward (no `grantId`) or a Saved Gift batch (`grantId`, `availableGifts`, its snapshotted terms).
struct LoyaltyReward: Decodable, Equatable {
    let grantId: String?
    let availableGifts: Int
    let version: String
    let id: String
    let name: String
    let nameEn: String?
    let nameAr: String?
    let threshold: Double
    let rewardType: String?
    let rewardValue: Double?
    let expiresAt: Date?
    let eligible: Bool
    /// `insufficient`, `used`, `unsupported` or `tier` when not eligible.
    let reason: String
    let repeats: Bool
    let requiresPurchase: Bool

    /// One row key: a Saved Gift batch shares its Reward's `id`.
    var key: String { grantId ?? id }

    var displayName: String { LoyaltyNames.display(name: name, en: nameEn, ar: nameAr) }
}

/// `POST /api/loyalty/:id/operations` answers with this (`LoyaltyResult`).
struct LoyaltyResult: Decodable, Equatable {
    let transactionId: String
    let balance: Double
    let amount: Double
    /// `earn` or `redeem`.
    let type: String
    let rewardName: String
    let rewardNameEn: String?
    let rewardNameAr: String?

    var displayRewardName: String { LoyaltyNames.display(name: rewardName, en: rewardNameEn, ar: rewardNameAr) }
}

enum LoyaltyNames {
    /// `rewardDisplayName` in waffi `packages/shared`: Arabic first on an Arabic phone, English otherwise, the base name last.
    static func display(name: String, en: String?, ar: String?) -> String {
        if Locale.current.language.languageCode?.identifier == "ar", let ar, !ar.isEmpty { return ar }
        if let en, !en.isEmpty { return en }
        return name
    }
}

/// One Customer of `GET /api/customer-tiers/directory`, with the Cards they can be served on.
struct DirectoryCustomer: Decodable, Identifiable, Equatable {
    struct CardEntry: Decodable, Identifiable, Equatable {
        let id: String
        let manualCode: String
        let balance: Double
        let unit: String
        let availableGifts: Int
    }

    let id: String
    let name: String
    let cards: [CardEntry]
}

struct DirectoryPage: Decodable {
    let items: [DirectoryCustomer]
    let nextCursor: String?
}
