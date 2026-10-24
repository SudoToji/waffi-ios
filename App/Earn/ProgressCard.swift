import SwiftUI

/// The Balance against the next Reward: "6 / 8 stamps", how far to go, and the stamp grid of a stamps Card.
struct ProgressCard: View {
    let card: StaffCard
    @ScaledMetric(relativeTo: .largeTitle) private var balanceSize: CGFloat = 44

    private var remaining: Int {
        guard let target = card.target else { return 0 }
        return max(0, Int((target.threshold - card.balance).rounded(.up)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                balanceText
                Spacer(minLength: 8)
                if let target = card.target { goal(target) }
            }
            if card.isStamps, let target = card.target, target.threshold >= 1, target.threshold <= 30 {
                StampGrid(count: Int(target.threshold), filled: Int(card.balance))
            }
            if card.savedGifts > 0 {
                Text("Saved Gifts available: \(card.savedGifts)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22))
    }

    private var balanceText: some View {
        let target = card.target.map { "/ \($0.threshold.formatted(.number)) \(card.unitLabel)" } ?? card.unitLabel
        return HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(card.balance, format: .number)
                .font(.system(size: balanceSize, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(Theme.text)
            Text(verbatim: target).font(.title3.weight(.semibold)).foregroundStyle(Theme.secondaryText)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func goal(_ target: LoyaltyReward) -> some View {
        Group {
            if remaining > 0 {
                Text("\(remaining) \(card.unitLabel) to go for \(target.displayName)")
            } else {
                Text("Ready to redeem")
            }
        }
        .font(.footnote)
        .foregroundStyle(Theme.secondaryText)
        .multilineTextAlignment(.trailing)
    }
}
