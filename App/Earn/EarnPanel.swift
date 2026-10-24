import SwiftUI

/// Earn on this Card: a stamp count on a stamps Card, the purchase amount on a points Card, one visit on an attendance Card.
struct EarnPanel: View {
    let model: EarnModel
    let card: StaffCard
    @State private var quantity = 1
    @State private var amountText = ""

    private var disabled: Bool { model.busyOrPending || model.unresolved != nil || model.branch == nil }
    private var amountMinor: Int? { PurchaseAmount.minorUnits(amountText) }
    private var valid: Bool { !card.takesPurchase || amountMinor != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if card.isStamps { stampStepper } else if card.takesPurchase { purchaseField } else {
                Text("Record one visit. No purchase amount needed.").font(.subheadline).foregroundStyle(Theme.secondaryText)
            }
            Button {
                model.prepareEarn(
                    quantity: card.isStamps ? quantity : nil, amountMinor: card.takesPurchase ? amountMinor : nil)
            } label: {
                Label { earnTitle } icon: { Image(systemName: "plus") }
            }
            .buttonStyle(.waffiPrimary)
            .disabled(disabled || !valid)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder private var earnTitle: some View {
        if card.isStamps {
            Text("Earn \(quantity) stamps")
        } else if card.takesPurchase {
            Text("Award purchase points")
        } else {
            Text("Record one visit")
        }
    }

    private var stampStepper: some View {
        HStack(spacing: 12) {
            Text("Stamps to add").font(.body.weight(.bold)).foregroundStyle(Theme.text)
            Spacer(minLength: 8)
            stepButton("Remove one stamp", systemImage: "minus") { quantity = max(1, quantity - 1) }
                .disabled(disabled || quantity <= 1)
            Text(quantity, format: .number)
                .font(.title2.weight(.heavy))
                .monospacedDigit()
                .foregroundStyle(Theme.text)
                .frame(minWidth: 36)
                .accessibilityLabel(Text("Number of stamps"))
            stepButton("Add one stamp", systemImage: "plus") { quantity = min(PurchaseAmount.maxStamps, quantity + 1) }
                .disabled(disabled || quantity >= PurchaseAmount.maxStamps)
        }
    }

    private func stepButton(_ title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.body.weight(.bold))
                .foregroundStyle(Theme.text)
                .frame(width: 44, height: 44)
                .background(Theme.track, in: .circle)
        }
    }

    private var purchaseField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Eligible purchase amount (EGP)").font(.body.weight(.bold)).foregroundStyle(Theme.text)
            TextField(text: $amountText, prompt: Text(verbatim: "0.00")) { Text("Eligible purchase amount (EGP)") }
                .keyboardType(.decimalPad)
                .environment(\.layoutDirection, .leftToRight)
                .waffiField()
                .disabled(disabled)
            Text("Use up to two decimal places. Required for points earning and monetary rewards.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            if !amountText.isEmpty && amountMinor == nil {
                Text("Enter a valid eligible purchase amount, up to EGP 1,000,000.")
                    .font(.footnote)
                    .foregroundStyle(Theme.warning)
            }
        }
    }
}
