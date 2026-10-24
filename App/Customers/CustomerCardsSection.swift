import SwiftUI

/// A Customer's Cards: the Card Template, its number, the Balance and the Saved Gifts waiting (`CustomerCards.tsx`).
struct CustomerCardsSection: View {
    let cards: [CustomerCard]
    /// A Card's id to its Card Tier's name (a `tier` Card), when it could be read.
    let cardTiers: [String: String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cards")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            if cards.isEmpty {
                Text("No card issued")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
            }
            ForEach(cards) { card in CardSummary(card: card, cardTier: cardTiers[card.id]) }
        }
    }
}

private struct CardSummary: View {
    let card: CustomerCard
    let cardTier: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: card.title).font(.headline.weight(.bold)).foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                Text("Card \(CustomerFormat.ltr(card.manualCode))")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(Theme.secondaryText)
            }
            if let cardTier {
                Label { Text("Card Tier \(cardTier)") } icon: { Image(systemName: "star") }
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.warning)
            }
            HStack(alignment: .top, spacing: 24) {
                figure(String(localized: "Points"), card.points)
                if card.cardType == "stamps" { figure(String(localized: "Stamps"), card.stamps) }
                if card.cardType == "attendance" { figure(String(localized: "Visits"), card.visits) }
                figure(String(localized: "Gifts"), Double(card.availableGifts ?? 0))
            }
            if !card.isActive {
                Text("Inactive card").font(.footnote.weight(.semibold)).foregroundStyle(Theme.warning)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private func figure(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: value.formatted(.number)).font(.title3.weight(.heavy)).monospacedDigit().foregroundStyle(Theme.text)
            Text(verbatim: label).font(.caption).foregroundStyle(Theme.secondaryText)
        }
    }
}
