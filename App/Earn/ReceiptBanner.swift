import SwiftUI

/// "Loyalty added" or "Reward redeemed", with the new Balance, until the next action.
struct ReceiptBanner: View {
    let model: EarnModel

    var body: some View {
        if let receipt = model.receipt {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Group {
                        if receipt.type == "redeem" { Text("Reward redeemed") } else { Text("Loyalty added") }
                    }
                    .font(.headline)
                    if !receipt.rewardName.isEmpty { Text(verbatim: receipt.rewardName).font(.subheadline.weight(.semibold)) }
                    Text(verbatim: balanceLine(receipt)).font(.subheadline)
                    if let card = model.card, card.savedGifts > 0 {
                        Text("Saved Gifts available: \(card.savedGifts)").font(.subheadline)
                    }
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.onAccent)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 20))
            .accessibilityElement(children: .combine)
        }
    }

    /// The website's `loyalty.saved` and `loyalty.savedRedeem`.
    private func balanceLine(_ receipt: OperationReceipt) -> String {
        let balance = receipt.balance.formatted(.number)
        if receipt.type == "redeem" { return String(localized: "Redeemed. Balance: \(balance) \(receipt.unit).") }
        let amount = receipt.amount.formatted(.number)
        return String(localized: "+\(amount) \(receipt.unit). Balance: \(balance) \(receipt.unit).")
    }
}
