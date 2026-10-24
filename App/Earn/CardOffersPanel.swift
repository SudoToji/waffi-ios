import SwiftUI

/// "Other offers": the Customer's Birthday offer and campaign coupons, each with Redeem (needs `loyalty.redeem`) and a confirmation.
/// Both leave a Transaction at the Branch served at and do not touch the Balance.
struct CardOffersPanel: View {
    let earn: EarnModel
    @State private var model: CardOffersModel

    init(earn: EarnModel, cardId: String) {
        self.earn = earn
        _model = State(initialValue: CardOffersModel(api: earn.api, cardId: cardId))
    }

    private var disabled: Bool { earn.busyOrPending || earn.unresolved != nil || earn.branch == nil || model.redeeming }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Other offers")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.secondaryText)
                .accessibilityAddTraits(.isHeader)
            Text("Birthday offers and Coupons are separate from loyalty Rewards. They do not spend the Card balance.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            if let redeemed = model.redeemed {
                Label(redeemedText(redeemed), systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            if let error = model.error ?? model.loadError {
                Text(error.message).font(.subheadline).foregroundStyle(Theme.warning).accessibilityAddTraits(.updatesFrequently)
            }
            if model.loading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 8)
            } else if model.isEmpty && model.loadError == nil {
                Text("No birthday offer available.").font(.subheadline).foregroundStyle(Theme.secondaryText)
                Text("No active campaign coupons for this card.").font(.subheadline).foregroundStyle(Theme.secondaryText)
            } else if !model.isEmpty {
                VStack(spacing: 0) {
                    ForEach(model.birthdays) { offer in
                        row(.birthday(offer), icon: "birthday.cake", title: offer.title, detail: offer.description, expiry: birthdayExpiry(offer.expiresAt), locale: offer.locale)
                    }
                    ForEach(model.coupons) { coupon in
                        row(.coupon(coupon), icon: "ticket", title: coupon.description, detail: nil, expiry: String(localized: "Expires \(cairo(coupon.expiresAt))"), locale: nil)
                    }
                }
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 22))
            }
        }
        .task { await model.load() }
        .confirmationDialog(
            confirmTitle, isPresented: Binding(get: { model.selected != nil }, set: { if !$0 { model.selected = nil } }),
            titleVisibility: .visible, presenting: model.selected
        ) { offer in
            Button(confirmTitle) {
                guard let branch = earn.branch else { return }
                Task { _ = await model.redeem(offer, branchId: branch.id) { await earn.offerBranchRefused() } }
            }
            Button("Cancel", role: .cancel) { model.selected = nil }
        } message: { offer in
            switch offer {
            case .coupon(let coupon):
                Text("\(coupon.description). Confirm only after providing this offer. This coupon can be redeemed once.")
            case .birthday(let birthday):
                Text("\(birthday.description). Hand over the complimentary item, then confirm. This offer can be redeemed once across the Business. It does not change stamps or Saved Gifts.")
            }
        }
    }

    private var confirmTitle: LocalizedStringKey {
        if case .birthday = model.selected { return "Redeem birthday offer" }
        return "Redeem coupon"
    }

    private func redeemedText(_ offer: CounterOffer) -> LocalizedStringKey {
        if case .birthday = offer { return "Birthday offer redeemed." }
        return "Coupon redeemed and recorded in transactions."
    }

    private func row(_ offer: CounterOffer, icon: String, title: String, detail: String?, expiry: String, locale: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Theme.accentTint, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: title).font(.body.weight(.bold)).foregroundStyle(Theme.text)
                if let detail, detail != title { Text(verbatim: detail).font(.footnote).foregroundStyle(Theme.secondaryText) }
                Text(verbatim: expiry).font(.footnote).foregroundStyle(Theme.secondaryText)
            }
            .multilineTextAlignment(.leading)
            .environment(\.layoutDirection, locale == "ar" ? .rightToLeft : .leftToRight)
            Spacer(minLength: 8)
            if earn.canRedeem {
                Button("Redeem") { model.selected = offer }
                    .buttonStyle(.waffiCompact)
                    .disabled(disabled)
                    .accessibilityLabel(Text("Redeem \(title)"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .contain)
    }

    private func cairo(_ date: Date) -> String {
        let zone = TimeZone(identifier: "Africa/Cairo") ?? .current
        return date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: zone))
    }

    private func birthdayExpiry(_ date: Date) -> String {
        String(localized: "Valid until \(cairo(date)) (Cairo time)")
    }
}
