import Foundation

/// The body of `POST /api/loyalty/:id/operations` (`LoyaltyInput`). `operationId` is the retry key: the same id never makes a second Transaction.
struct OperationInput: Codable, Equatable {
    var operationId: String
    var branchId: String
    /// `earn` or `redeem`.
    var type: String
    var grantId: String?
    var rewardId: String?
    var rewardVersion: String?
    /// The purchase amount in piastres.
    var amountMinor: Int?
    /// Stamps added by one Earn on a stamps Card.
    var quantity: Int?
    /// A Redeem of a live Reward states the Balance it was shown, so a Balance that moved is refused.
    var expectedBalance: Int?
    var currency = "EGP"
}

/// An Operation that was sent, or may have been: kept on the phone until the server answers for good, so a retry reuses its `operationId`.
struct PendingOperation: Codable, Equatable {
    var cardId: String
    /// The Manual Code, to read the Card again afterwards.
    var code: String
    var customerName: String
    var unit: String
    var rewardName: String
    var input: OperationInput
}

/// What the Staff Member is about to confirm. Nothing is sent, and no `operationId` exists, until Confirm.
struct OperationDraft: Identifiable, Equatable {
    let id = UUID()
    /// `earn` or `redeem`.
    let type: String
    let reward: LoyaltyReward?
    let quantity: Int?
    let amountMinor: Int?
    /// A Reward bought with a purchase: the confirm sheet asks for the amount.
    let needsAmount: Bool

    /// What the Operation deducts from the Balance, for the confirmation text (a Saved Gift or a milestone Reward deducts nothing).
    var cost: Int {
        guard let reward else { return quantity ?? 1 }
        return reward.grantId == nil && reward.repeats ? Int(reward.threshold) : 0
    }
}

/// What the green banner shows after a success.
struct OperationReceipt: Equatable {
    let type: String
    let amount: Double
    let balance: Double
    let unit: String
    let rewardName: String
}

/// A line of "Recently served": this phone's own last Operations (kept in memory only).
struct RecentServe: Identifiable, Equatable {
    let id = UUID()
    let customerName: String
    let summary: String
    let date: Date
}
