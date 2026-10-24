import SwiftUI

/// "Rewards": what the Customer can redeem now (live Rewards and Saved Gifts), then what is locked. Redeem needs `loyalty.redeem`.
struct RewardsPanel: View {
    let model: EarnModel
    let card: StaffCard

    private var disabled: Bool { model.busyOrPending || model.unresolved != nil || model.branch == nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rewards")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.secondaryText)
                .accessibilityAddTraits(.isHeader)
            if card.rewards.isEmpty {
                Text("No Rewards are ready yet. Keep earning to unlock one.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.vertical, 8)
            } else {
                let rewards = card.readyRewards + card.lockedRewards
                VStack(spacing: 0) {
                    ForEach(rewards, id: \.key) { reward in
                        if reward.key != rewards.first?.key { Rectangle().fill(Theme.border).frame(height: 1 / 3) }
                        RewardRow(card: card, reward: reward, canRedeem: model.canRedeem, disabled: disabled) {
                            model.prepareRedeem(reward)
                        }
                    }
                }
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 22))
            }
        }
    }
}
