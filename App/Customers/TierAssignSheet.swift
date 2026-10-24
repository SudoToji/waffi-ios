import SwiftUI

/// Giving a Customer a higher Customer Tier: optionally tell them through the wallet pass (`CustomerTierAssignment` on the website).
struct TierAssignSheet: View {
    let model: CustomerDetailModel
    let tier: CustomerTier
    @State private var tellCustomer = false
    @Environment(\.dismiss) private var dismiss

    private var hasPass: Bool { model.customer.hasTierMessagePass == true }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(verbatim: tier.displayName).font(.headline)
                    Toggle("Tell the Customer", isOn: $tellCustomer).disabled(!hasPass || model.busy)
                } footer: {
                    if !hasPass { Text("No wallet pass to send to") }
                }
                if let error = model.actionError {
                    Section { Text(error.message).foregroundStyle(Theme.warning) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(Text("Assign tier for \(model.customer.name)"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(model.busy) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save tier") {
                        Task {
                            if await model.assignTier(tier, tellCustomer: tellCustomer && hasPass) { dismiss() }
                        }
                    }
                    .disabled(model.busy)
                }
            }
            .interactiveDismissDisabled(model.busy)
        }
        .presentationDetents([.medium])
    }
}
