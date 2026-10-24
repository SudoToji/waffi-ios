import SwiftUI

/// What happened to a message's deliveries, over every time it was sent (the website's delivery results, without the per-Customer list).
struct ResultsSheet: View {
    let message: SavedMessage
    let counts: [String: Int]
    @Environment(\.dismiss) private var dismiss

    private var waiting: Int { (counts["pending"] ?? 0) + (counts["processing"] ?? 0) + (counts["retry"] ?? 0) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(verbatim: message.latest.title).font(.headline)
                    Text("Sent \(message.sends.count) times")
                } footer: {
                    Text("Accepted means the message was placed on the customer’s pass. It does not confirm that a customer saw it. Uncertain outcomes are not automatically resent.")
                }
                Section {
                    row("Waiting", waiting)
                    row("Placed on the pass", counts["accepted"] ?? 0)
                    row("Skipped", counts["skipped"] ?? 0)
                    row("Failed", counts["failed"] ?? 0)
                    row("Needs review", counts["uncertain"] ?? 0)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Delivery results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ title: LocalizedStringKey, _ number: Int) -> some View {
        LabeledContent(title) { Text(number.formatted()).monospacedDigit() }
    }
}
