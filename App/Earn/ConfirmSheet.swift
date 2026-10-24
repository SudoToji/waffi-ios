import SwiftUI

/// "Confirm transaction": says what will happen to this Customer's Card, and sends it on Confirm (the website's confirmation dialog).
struct ConfirmSheet: View {
    let model: EarnModel
    let draft: OperationDraft
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""

    private var enteredAmount: Int? { PurchaseAmount.minorUnits(amountText) }
    private var canConfirm: Bool { !model.busy && (!draft.needsAmount || enteredAmount != nil) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Confirm transaction").font(.title3.weight(.heavy)).foregroundStyle(Theme.text)
                if let card = model.card {
                    Text(verbatim: "\(card.customerName) · \(card.manualCode)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .accessibilityAddTraits(.isHeader)
            message.foregroundStyle(Theme.text)
            if draft.needsAmount {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Eligible purchase amount (EGP)").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                    TextField(text: $amountText, prompt: Text(verbatim: "0.00")) { Text("Eligible purchase amount (EGP)") }
                        .keyboardType(.decimalPad)
                        .environment(\.layoutDirection, .leftToRight)
                        .waffiField()
                    Text("Use up to two decimal places. Required for points earning and monetary rewards.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                    if !amountText.isEmpty && enteredAmount == nil {
                        Text("Enter a valid eligible purchase amount, up to EGP 1,000,000.")
                            .font(.footnote)
                            .foregroundStyle(Theme.warning)
                    }
                }
            }
            Spacer(minLength: 0)
            Button {
                Task { await model.confirm(amountMinor: enteredAmount) }
            } label: {
                if model.busy { ProgressView() } else { Text("Confirm transaction") }
            }
            .buttonStyle(.waffiPrimary)
            .disabled(!canConfirm)
            Button("Cancel") { dismiss() }
                .buttonStyle(.waffiTinted)
                .disabled(model.busy)
        }
        .padding(20)
        .background(Theme.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(model.busy)
    }

    /// The website's confirmation texts: a Saved Gift, a milestone Reward, a Reward that spends the Balance, a purchase, stamps, or one visit.
    @ViewBuilder private var message: some View {
        if draft.type == "redeem", let reward = draft.reward {
            let name = reward.displayName
            if reward.grantId != nil {
                Text("Give the customer \(name). Redeem one saved gift without changing their current stamps or points. Fulfill it only after success is shown.")
            } else if draft.cost == 0 {
                Text("Redeem \(name) once. The balance stays unchanged. Fulfill the gift only after success is shown.")
            } else {
                Text("Redeem \(name) and deduct \(draft.cost) from the balance. Fulfill the gift only after success is shown.")
            }
        } else if let amount = draft.amountMinor {
            let text = (Double(amount) / 100).formatted(.number.precision(.fractionLength(2)))
            Text("Record an eligible purchase of EGP \(text) and award points at the configured rate.")
        } else if let quantity = draft.quantity {
            if quantity == 1 {
                Text("Add one stamp to this Customer's Card. Confirm only after a qualifying purchase.")
            } else {
                Text("Confirm \(quantity) qualifying purchases. This adds \(quantity) stamps.")
            }
        } else {
            Text("Confirm one qualifying purchase or check-in. This adds one unit.")
        }
    }
}
