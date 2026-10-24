import SwiftUI

/// A draft that saved itself: tap to keep writing, Send to confirm and send it.
struct DraftCard: View {
    let draft: Campaign
    let tiers: [CustomerTier]
    let branches: [StaffBranch]
    let disabled: Bool
    let sendEnabled: Bool
    let onEdit: () -> Void
    let onSend: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Button(action: onEdit) {
                    Text(verbatim: draft.title.isEmpty ? draft.body : draft.title + "\n" + draft.body)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(4)
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .environment(\.layoutDirection, draft.locale == "ar" ? .rightToLeft : .leftToRight)
                .accessibilityHint(Text("Opens the draft"))
                Menu {
                    Button("Edit draft", systemImage: "square.and.pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Label("More", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
            }
            MessageChips(campaign: draft, tiers: tiers, branches: branches)
            Text("Draft · saved").font(.footnote).foregroundStyle(Theme.secondaryText)
            Button(action: onSend) {
                Label("Send", systemImage: "paperplane")
            }
            .buttonStyle(.waffiPrimary)
            .disabled(disabled || !sendEnabled)
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
    }
}
