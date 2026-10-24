import SwiftUI

/// A Customer's Card: who, how far along, earn, and the Rewards they can redeem.
struct CardScreen: View {
    let model: EarnModel

    var body: some View {
        if let card = model.card {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    backButton
                    RecoveryPanel(model: model)
                    ReceiptBanner(model: model)
                    if let today = card.today { TodayWarning(today: today) }
                    identity(card)
                    ProgressCard(card: card)
                    if let error = model.lookupError {
                        Text(error.message).font(.subheadline).foregroundStyle(Theme.warning)
                    }
                    if model.branch == nil {
                        Text("No Branch is available. Ask the Owner to assign you to one.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.warning)
                    }
                    if model.canEarn { EarnPanel(model: model, card: card).id(card.id) }
                    RewardsPanel(model: model, card: card)
                    CardOffersPanel(earn: model, cardId: card.id).id(card.id)
                    if !model.canEarn && !model.canRedeem {
                        Text("You have view-only access. Ask your owner for permission to add progress or redeem rewards.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    walletSync(card)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if model.busy { ProgressView().controlSize(.large).padding(24).background(.regularMaterial, in: .rect(cornerRadius: 16)) }
            }
        }
    }

    private var backButton: some View {
        Button { model.clearCustomer() } label: {
            Label("Earn & redeem", systemImage: "chevron.backward")
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .foregroundStyle(Theme.accent)
        .disabled(model.busyOrPending)
        .padding(.top, 8)
    }

    private func identity(_ card: StaffCard) -> some View {
        HStack(spacing: 14) {
            Avatar(name: card.customerName, size: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: card.customerName).font(.title3.weight(.heavy)).foregroundStyle(Theme.text)
                Text("Card \(card.manualCode)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 8)
            if card.cardType == "tier" && !card.tierName.isEmpty {
                Label { Text(verbatim: card.tierName) } icon: { Image(systemName: "star") }
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.warning)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.warning.opacity(0.15), in: .capsule)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("Card Tier \(card.tierName)"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    /// The Google Wallet pass is updated by the server after each Operation; this says where it stands.
    @ViewBuilder private func walletSync(_ card: StaffCard) -> some View {
        if let state = card.walletSync, state != "not_connected" {
            HStack {
                Group {
                    switch state {
                    case "synced": Text("Google Wallet is up to date")
                    case "retrying": Text("Google Wallet update delayed. We will retry automatically.")
                    default: Text("Google Wallet update pending")
                    }
                }
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                Spacer(minLength: 8)
                Button("Refresh status") { Task { await model.refreshCard() } }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(minHeight: 44)
                    .disabled(model.busyOrPending)
            }
        }
    }
}
