import SwiftUI

/// A message held for a time. Cancel puts it back among the drafts; one that is not armed yet offers Activate.
struct ScheduledRow: View {
    let campaign: Campaign
    let tiers: [CustomerTier]
    let branches: [StaffBranch]
    let disabled: Bool
    let activateEnabled: Bool
    let onCancel: () -> Void
    let onActivate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Theme.accentTint, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: campaign.title).font(.subheadline.weight(.bold)).lineLimit(1).foregroundStyle(Theme.text)
                Text(verbatim: detail).font(.footnote).foregroundStyle(Theme.secondaryText)
                if campaign.deliveryPaused {
                    Text("Delivery paused").font(.footnote.weight(.semibold)).foregroundStyle(Theme.warning)
                }
            }
            .environment(\.layoutDirection, campaign.locale == "ar" ? .rightToLeft : .leftToRight)
            Spacer(minLength: 8)
            VStack(spacing: 4) {
                if campaign.deliveryPaused {
                    Button("Activate delivery", action: onActivate)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Theme.accent)
                        .frame(minHeight: 44)
                        .disabled(disabled || !activateEnabled)
                }
                Button("Cancel schedule", action: onCancel)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.warning)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border))
                    .disabled(disabled)
            }
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.accent.opacity(0.5)))
    }

    /// "Fri 30 Oct, 10:00 · Gold", in the time zone the Owner scheduled it in.
    private var detail: String {
        let zone = campaign.scheduleTimezone.flatMap(TimeZone.init(identifier:)) ?? .current
        let when = campaign.scheduledAt?.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: zone)) ?? ""
        return when + " · " + AudienceLabel.chip(campaign, tiers: tiers, branches: branches)
    }
}
