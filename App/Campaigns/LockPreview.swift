import SwiftUI

/// What the Customer sees on the lock screen: the message as a notification, with the coupon line.
struct LockPreview: View {
    let business: String
    let form: MessageForm

    private var direction: LayoutDirection { form.locale == "ar" ? .rightToLeft : .leftToRight }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PREVIEW · LOCK SCREEN")
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.6))
            HStack(alignment: .top, spacing: 12) {
                WaffiMark(size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(verbatim: business).font(.subheadline.weight(.bold))
                        Spacer(minLength: 8)
                        Text("now").font(.footnote).foregroundStyle(.secondary)
                    }
                    Group {
                        if form.title.isEmpty && form.body.isEmpty {
                            Text("Write a message to see it here.").foregroundStyle(.secondary)
                        } else {
                            Text(verbatim: [form.title, form.body].filter { !$0.isEmpty }.joined(separator: "\n"))
                        }
                    }
                    .font(.subheadline)
                    .environment(\.layoutDirection, direction)
                    if form.coupon {
                        Text("Coupon: \(form.couponDescription.isEmpty ? String(localized: "Coupon") : form.couponDescription)")
                            .font(.subheadline.weight(.semibold))
                            .environment(\.layoutDirection, direction)
                    }
                }
                .foregroundStyle(Color.black.opacity(0.85))
            }
            .padding(12)
            .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color(red: 0.16, green: 0.27, blue: 0.21), Color(red: 0.07, green: 0.12, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .accessibilityElement(children: .combine)
    }
}
