import SwiftUI

/// Type the six digits printed under the Card's QR (a phone number in international form works too).
struct ManualCodeSheet: View {
    let model: EarnModel
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Six-digit Card number or international phone").foregroundStyle(Theme.secondaryText)
                TextField(text: $code, prompt: Text(verbatim: "123456")) { Text("Manual Code") }
                    .keyboardType(.phonePad)
                    .environment(\.layoutDirection, .leftToRight)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .waffiField()
                    .focused($focused)
                if model.codeInvalid {
                    Text("Enter six card digits, a Waffi QR code, or a phone number. Local numbers use Egypt; include +country code for other countries.").font(.subheadline).foregroundStyle(Theme.warning)
                } else if let error = model.lookupError {
                    Text(error.message).font(.subheadline).foregroundStyle(Theme.warning)
                }
                Button {
                    Task { if await model.lookup(code) { dismiss() } }
                } label: {
                    if model.searching { ProgressView() } else { Text("Find customer") }
                }
                .buttonStyle(.waffiPrimary)
                .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty || model.searching)
                Spacer()
            }
            .padding(16)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Enter Manual Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}
