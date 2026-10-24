import SwiftUI

/// "Attach a coupon": a one-time in-store offer. The kind writes the offer text for the Owner; the API stores the text,
/// the hours (or a fixed expiry) only.
struct CouponSection: View {
    @Bindable var model: ComposerModel

    private var direction: LayoutDirection { model.form.locale == "ar" ? .rightToLeft : .leftToRight }

    var body: some View {
        ComposerCard {
            Toggle(isOn: $model.form.coupon) {
                HStack(spacing: 12) {
                    Image(systemName: "gift")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 40, height: 40)
                        .background(Theme.accentTint, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Attach a coupon").font(.headline).foregroundStyle(Theme.text)
                        if model.form.coupon, !model.form.couponDescription.isEmpty {
                            Text(verbatim: model.form.couponDescription).font(.footnote).foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
            }
            .tint(Theme.accent)
            if model.form.coupon { details }
        }
    }

    @ViewBuilder private var details: some View {
        Picker("Coupon type", selection: $model.form.couponKind) {
            ForEach(CouponKind.allCases) { kind in Text(kind.title).tag(kind) }
        }
        .pickerStyle(.menu)
        .tint(Theme.accent)
        .onChange(of: model.form.couponKind) { model.form.couponDetail = "" }
        Group {
            switch model.form.couponKind {
            case .custom:
                TextField("Coupon offer", text: $model.form.couponText).waffiField()
            case .freeItem:
                TextField("Item", text: $model.form.couponDetail, prompt: Text("Coffee")).waffiField()
            case .discountPercent:
                TextField("Discount (%)", text: $model.form.couponDetail).keyboardType(.decimalPad).waffiField()
            case .discountAmount:
                TextField("Discount (EGP)", text: $model.form.couponDetail).keyboardType(.decimalPad).waffiField()
            }
        }
        .environment(\.layoutDirection, direction)
        if model.form.couponKind != .custom {
            Text("Customers will see: \(model.form.couponDescription)")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .environment(\.layoutDirection, direction)
        }
        Picker("Coupon expiry", selection: $model.form.fixedExpiry) {
            Text("Duration after processing starts").tag(false)
            Text("Expiry date and time").tag(true)
        }
        .pickerStyle(.menu)
        .tint(Theme.accent)
        if model.form.fixedExpiry {
            DatePicker(
                "Expiry date and time", selection: $model.form.couponExpiresAt,
                in: Date.now.addingTimeInterval(120)...Date.now.addingTimeInterval(364 * 86400))
        } else {
            Stepper(value: $model.form.couponHours, in: 1...720) {
                Text("Valid for \(model.form.couponHours) hours")
            }
        }
        Text("A one-time in-store offer. Staff redeem it using the customer’s card; no stamps or points are deducted.")
            .font(.footnote)
            .foregroundStyle(Theme.secondaryText)
    }
}
