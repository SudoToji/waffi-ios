import SwiftUI

/// The private Card link, shown once: copy it, share it, or send it on WhatsApp. It carries the Card's secret, so it is kept nowhere.
struct CardLinkSheet: View {
    let model: CustomerDetailModel
    @State private var copied = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let link = model.link {
                        Text("Send this link to \(model.customer.name). Anyone who opens it can see the card, so share it privately. It is shown only once.")
                            .foregroundStyle(Theme.text)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Private card link").font(.footnote.weight(.semibold)).foregroundStyle(Theme.secondaryText)
                            Text(verbatim: link.absoluteString)
                                .font(.footnote.monospaced())
                                .foregroundStyle(Theme.text)
                                .textSelection(.enabled)
                                .environment(\.layoutDirection, .leftToRight)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border))
                        }
                        Button {
                            UIPasteboard.general.string = link.absoluteString
                            copied = true
                        } label: {
                            Label(copyTitle, systemImage: copied ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(.waffiPrimary)
                        ShareLink(item: link) {
                            Label("Share link", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.waffiTinted)
                        if let whatsApp = model.whatsAppURL(link: link) {
                            Button { openURL(whatsApp) } label: {
                                Label("Send on WhatsApp", systemImage: "message")
                            }
                            .buttonStyle(.waffiTinted)
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Card link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private var copyTitle: LocalizedStringKey { copied ? "Copied" : "Copy link" }
}
