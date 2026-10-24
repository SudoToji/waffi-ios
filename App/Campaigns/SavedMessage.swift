import Foundation

/// One message the Owner has sent, however many times: campaigns with the same message, audience and coupon are one card
/// ("Sent 3 times"). The API has no resend, so every send is its own campaign with its own delivery report.
struct SavedMessage: Identifiable, Equatable {
    /// The sends, newest first.
    let sends: [Campaign]

    var latest: Campaign { sends[0] }
    var id: String { Self.key(latest) }
    /// A send is still going out: Send again waits for it, and Stop is offered.
    var sending: Campaign? { sends.first { $0.status == "processing" } }

    /// What makes two campaigns the same message: the text (and its translation), who it went to, and the coupon.
    static func key(_ campaign: Campaign) -> String {
        func trimmed(_ text: String) -> String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
        var parts = [
            campaign.locale, trimmed(campaign.title), trimmed(campaign.body),
            campaign.translation.map { trimmed($0.title) + "\u{1F}" + trimmed($0.body) } ?? "",
            campaign.audience,
            campaign.coupon.map { trimmed($0.description) + "\u{1F}" + String($0.validHours) } ?? "",
        ]
        switch campaign.audience {
        case "inactive": parts.append(String(campaign.inactiveDays))
        case "tiers": parts.append((campaign.tierIds ?? []).sorted().joined(separator: ","))
        case "customer": parts.append(campaign.customerCode ?? "")
        case "joining_branch": parts.append(campaign.branchId ?? "")
        case "birthday_range": parts.append((campaign.birthdayFrom ?? "") + (campaign.birthdayTo ?? ""))
        default: break
        }
        return parts.joined(separator: "\u{1E}")
    }

    /// Groups sent campaigns (any order) into messages, the most recently sent first.
    static func groups(_ sent: [Campaign]) -> [SavedMessage] {
        var order: [String] = []
        var byKey: [String: [Campaign]] = [:]
        for campaign in sent.sorted(by: { $0.sentAt > $1.sentAt }) {
            let groupKey = key(campaign)
            if byKey[groupKey] == nil { order.append(groupKey) }
            byKey[groupKey, default: []].append(campaign)
        }
        return order.compactMap { byKey[$0].map(SavedMessage.init(sends:)) }
    }
}
