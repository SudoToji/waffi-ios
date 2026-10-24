import SwiftUI

/// One Reward or Saved Gift batch: what it is, why it is locked, and the Redeem button.
struct RewardRow: View {
    let card: StaffCard
    let reward: LoyaltyReward
    let canRedeem: Bool
    let disabled: Bool
    let onRedeem: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reward.eligible ? "gift" : "lock")
                .font(.body.weight(.semibold))
                .foregroundStyle(reward.eligible ? Theme.accent : Theme.secondaryText)
                .frame(width: 44, height: 44)
                .background(reward.eligible ? Theme.accentTint : Theme.track, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: reward.displayName)
                    .font(.body.weight(.bold))
                    .foregroundStyle(reward.eligible ? Theme.text : Theme.secondaryText)
                Text(verbatim: detail).font(.footnote).foregroundStyle(Theme.secondaryText)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            if reward.eligible {
                if canRedeem {
                    Button("Redeem", action: onRedeem)
                        .buttonStyle(.waffiCompact)
                        .disabled(disabled)
                        .accessibilityLabel(Text("Redeem \(reward.displayName)"))
                }
            } else {
                Text("Locked")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(Theme.track.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .contain)
    }

    private var detail: String {
        var parts: [String] = []
        let threshold = "\(reward.threshold.formatted(.number)) \(card.unitLabel)"
        if reward.grantId != nil {
            parts.append(String(localized: "Saved gift"))
            if let terms { parts.append(terms) }
            if reward.availableGifts > 1 { parts.append(String(localized: "Unclaimed gifts: \(reward.availableGifts)")) }
            if let expiry = reward.expiresAt { parts.append(String(localized: "Expires \(Self.expiryDate(expiry))")) }
        } else {
            parts.append(threshold)
            if !reward.eligible { parts.append(lockedReason) }
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private var lockedReason: String {
        switch reward.reason {
        case "insufficient":
            let remaining = max(0, Int((reward.threshold - card.balance).rounded(.up)))
            return String(localized: "\(remaining) more to go")
        case "used": return String(localized: "Already redeemed")
        case "unsupported": return String(localized: "This reward cannot be redeemed")
        case "tier": return String(localized: "Membership level required")
        default: return ""
        }
    }

    /// "Free item", or "Percentage discount · 20%": the terms a Saved Gift batch snapshotted.
    private var terms: String? {
        guard let type = reward.rewardType else { return nil }
        let label: String
        switch type {
        case "free_item": label = String(localized: "Free item")
        case "discount_percent": label = String(localized: "Percentage discount")
        case "discount_amount": label = String(localized: "Fixed discount")
        case "cashback": label = String(localized: "Cashback")
        default: label = String(localized: "Custom reward")
        }
        guard let value = reward.rewardValue else { return label }
        let number = value.formatted(.number)
        return "\(label) · " + (type == "discount_percent" ? "\(number)%" : "\(number) \(card.currency)")
    }

    /// The Cairo day a Saved Gift is last valid. The API's `expiresAt` is the first instant of the next day, so one millisecond earlier.
    private static func expiryDate(_ expiresAt: Date) -> String {
        let cairo = TimeZone(identifier: "Africa/Cairo") ?? .current
        return expiresAt.addingTimeInterval(-0.001).formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: cairo))
    }
}
