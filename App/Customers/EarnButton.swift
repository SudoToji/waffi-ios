import SwiftUI

/// "Earn & redeem" at the foot of a Customer's page: opens the Earn & redeem tab on their Card, or on the one they pick.
struct EarnButton: View {
    let cards: [CustomerCard]
    let open: (String) -> Void

    var body: some View {
        Group {
            if cards.count == 1, let card = cards.first {
                Button { open(card.manualCode) } label: { label }
            } else {
                Menu {
                    ForEach(cards) { card in
                        Button { open(card.manualCode) } label: {
                            Text(verbatim: "\(card.title) \u{00B7} \(CustomerFormat.ltr(card.manualCode))")
                        }
                    }
                } label: {
                    label
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var label: some View {
        Label("Earn & redeem", systemImage: "qrcode.viewfinder")
            .font(.headline.weight(.bold))
            .foregroundStyle(Theme.onAccent)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
            .contentShape(.rect)
    }
}
