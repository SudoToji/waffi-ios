import SwiftUI

/// The one confirmation before a message goes out: how many Customers get it, and what it says.
struct SendConfirmSheet: View {
    let model: SendModel
    let tiers: [CustomerTier]
    let branches: [StaffBranch]
    /// Called after the send is queued, with the number of recipients when known.
    let onSent: (Int?) -> Void
    @Environment(\.dismiss) private var dismiss

    init(model: SendModel, tiers: [CustomerTier] = [], branches: [StaffBranch] = [], onSent: @escaping (Int?) -> Void) {
        self.model = model
        self.tiers = tiers
        self.branches = branches
        self.onSent = onSent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            title.font(.title2.weight(.heavy)).foregroundStyle(Theme.text).accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: model.campaign.title).font(.subheadline.weight(.bold))
                Text(verbatim: model.campaign.body).font(.subheadline)
                Text(verbatim: summary).font(.footnote.weight(.semibold)).foregroundStyle(Theme.secondaryText)
            }
            .foregroundStyle(Theme.text)
            .environment(\.layoutDirection, model.campaign.locale == "ar" ? .rightToLeft : .leftToRight)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 14))
            Text("The message goes to the customer’s wallet pass. Whether the notification shows depends on the customer’s settings.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            if let error = model.error ?? model.countError {
                Text(error.message).font(.footnote).foregroundStyle(Theme.warning).accessibilityAddTraits(.updatesFrequently)
            }
            Spacer(minLength: 0)
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.waffiTinted)
                    .disabled(model.sending)
                Button {
                    Task { if await model.send() { onSent(model.recipients) } }
                } label: {
                    if model.sending { ProgressView() } else { Text("Send") }
                }
                .buttonStyle(.waffiPrimary)
                .disabled(model.sending)
            }
        }
        .padding(20)
        .background(Theme.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(model.sending)
        .task { if model.counts == nil { await model.loadCounts() } }
    }

    @ViewBuilder private var title: some View {
        if let recipients = model.recipients { Text("Send to \(recipients) Customers now?") } else { Text("Send this message now?") }
    }

    /// "Gold · Free pastry coupon attached".
    private var summary: String {
        var parts = [AudienceLabel.chip(model.campaign, tiers: tiers, branches: branches)]
        if let coupon = model.campaign.coupon { parts.append(String(localized: "\(coupon.description) coupon attached")) }
        return parts.joined(separator: " · ")
    }
}
