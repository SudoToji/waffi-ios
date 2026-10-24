import SwiftUI

/// An Operation that was sent but not answered for good: retry it with the same retry key, or (once the server refused it) drop it.
struct RecoveryPanel: View {
    let model: EarnModel

    var body: some View {
        if let pending = model.unresolved, model.draft == nil {
            VStack(alignment: .leading, spacing: 10) {
                Text(verbatim: pending.customerName).font(.headline).foregroundStyle(Theme.text)
                if let error = model.operationError {
                    Text(error.message).font(.subheadline).foregroundStyle(Theme.warning)
                }
                Text("The last operation needs confirmation from the server. Retry it safely before starting another.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.text)
                Button {
                    Task { await model.retry() }
                } label: {
                    if model.busy { ProgressView() } else { Text("Retry same operation") }
                }
                .buttonStyle(.waffiPrimary)
                .disabled(model.busy)
                if model.definitiveFailure {
                    Button("Return to card lookup") { model.dismissFailure() }
                        .buttonStyle(.waffiTinted)
                        .disabled(model.busy)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.warning.opacity(0.6)))
        }
    }
}
