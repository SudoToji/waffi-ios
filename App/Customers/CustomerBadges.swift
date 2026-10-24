import SwiftUI

/// The Customer Tier's name in a capsule.
struct TierBadge: View {
    let tier: CustomerTier

    var body: some View {
        Label { Text(verbatim: tier.displayName) } icon: { Image(systemName: "star") }
            .font(.footnote.weight(.bold))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.accentTint, in: .capsule)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Customer tier \(tier.displayName)"))
    }
}

/// "Returning" or "Loyal": visible to the Business only.
struct LoyaltyMarkBadge: View {
    let mark: String?

    var body: some View {
        switch mark {
        case "loyal": badge(Text("Loyal"))
        case "returning": badge(Text("Returning"))
        default: EmptyView()
        }
    }

    private func badge(_ text: Text) -> some View {
        text
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.track, in: .capsule)
    }
}

/// A filter choice: filled when it is the one in use.
struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? Theme.onAccent : Theme.text)
                .padding(.horizontal, 16)
                .frame(minHeight: 40)
                .background(selected ? Theme.accent : Theme.card, in: .capsule)
                .overlay(Capsule().strokeBorder(selected ? Color.clear : Theme.border))
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
