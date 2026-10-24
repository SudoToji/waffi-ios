import Foundation

/// One Transaction of `GET /api/transactions` (`TransactionRow` in waffi `packages/shared`), reduced to what the Overview lists.
struct ActivityRow: Decodable, Identifiable, Equatable {
    let id: String
    let createdAt: Date
    /// `earn`, `redeem` or `adjust`.
    let type: String
    /// `reward_unlock`, `reversal`, `gift_expired`, `import`, or something else for a plain earn or redeem.
    let source: String?
    /// Signed: a redeem is negative.
    let amount: Double
    let unit: String
    let customerName: String
    let rewardName: String
    let rewardNameEn: String?
    let rewardNameAr: String?
    let branchName: String?
    let reversed: Bool?

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
        case "redeem":
            let reward = Locale.current.language.languageCode?.identifier == "ar" ? rewardNameAr : rewardNameEn
            let name = reward ?? rewardName
            return name.isEmpty ? String(localized: "Redeemed") : String(localized: "Redeemed \(name)")
        default: return String(localized: "Adjustment")
        }
    }

    /// The title, then the Branch when there is one: "Earned · Zamalek".
    var subtitle: String {
        [title, branchName].compactMap { $0 }.joined(separator: " · ")
    }
}

/// `GET /api/transactions`: newest first; the Overview reads only the first rows.
struct ActivityPage: Decodable {
    let items: [ActivityRow]
}
