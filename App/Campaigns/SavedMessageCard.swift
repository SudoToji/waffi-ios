import SwiftUI

/// A message that was sent, once, however many times: its text, who got it, "Sent 3 times · last 2 days ago", how many it
/// reached, and Send again.
struct SavedMessageCard: View {
    let message: SavedMessage
    let delivered: Int?
    let tiers: [CustomerTier]
    let branches: [StaffBranch]
    let disabled: Bool
    let onAgain: () -> Void
    let onEdit: () -> Void
    let onResults: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Button(action: onEdit) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: message.latest.title).font(.subheadline.weight(.bold))
                        Text(verbatim: message.latest.body).font(.subheadline).lineLimit(3)
                    }
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .environment(\.layoutDirection, message.latest.locale == "ar" ? .rightToLeft : .leftToRight)
                .accessibilityHint(Text("Opens a new draft with this message"))
                Menu {
                    Button("Edit as a new draft", systemImage: "square.and.pencil", action: onEdit)
                    Button("Delivery results", systemImage: "chart.bar", action: onResults)
                } label: {
                    Label("More", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
            }
            MessageChips(campaign: message.latest, tiers: tiers, branches: branches)
            HStack {
                Text(verbatim: sentLine).font(.footnote).foregroundStyle(Theme.secondaryText)
                Spacer(minLength: 8)
                if let delivered {
                    Label("\(delivered) delivered", systemImage: "checkmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            if message.sending != nil {
                HStack {
                    Label("Sending now", systemImage: "arrow.up.circle").font(.footnote.weight(.semibold)).foregroundStyle(Theme.warning)
                    Spacer()
                    Button("Stop sending", action: onStop)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Theme.warning)
                        .frame(minHeight: 44)
                        .disabled(disabled)
                }
            } else {
                Button(action: onAgain) {
                    Label("Send again", systemImage: "repeat")
                }
                .buttonStyle(.waffiPrimary)
                .disabled(disabled)
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
    }

    /// "Sent 3 times · last 2 days ago".
    private var sentLine: String {
        let times = String(localized: "Sent \(message.sends.count) times")
        let when = message.latest.sentAt
        if abs(when.timeIntervalSinceNow) < 60 { return times + " · " + String(localized: "just now") }
        let relative = when.formatted(.relative(presentation: .numeric))
        return times + " · " + String(localized: "last \(relative)")
    }
}
