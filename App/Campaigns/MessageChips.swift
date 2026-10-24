import SwiftUI

/// The audience and the coupon of a message, as small tags under its text.
struct MessageChips: View {
    let campaign: Campaign
    let tiers: [CustomerTier]
    let branches: [StaffBranch]

    var body: some View {
        HStack(spacing: 6) {
            chip(AudienceLabel.chip(campaign, tiers: tiers, branches: branches), icon: "person", color: Theme.accent, fill: Theme.accentTint)
            if let coupon = campaign.coupon {
                chip(coupon.description, icon: "gift", color: Theme.warning, fill: Theme.warning.opacity(0.15))
            }
            Spacer(minLength: 0)
        }
    }

    private func chip(_ text: String, icon: String, color: Color, fill: Color) -> some View {
        Label { Text(verbatim: text).lineLimit(1) } icon: { Image(systemName: icon).imageScale(.small) }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(fill, in: .capsule)
    }
}
