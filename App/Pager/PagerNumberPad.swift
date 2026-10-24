import SwiftUI

/// The order number as typed or tapped, and the button that makes the ticket and shows its QR. Letters come from the keyboard;
/// the pad is the fast path for digits.
struct PagerNumberPad: View {
    @Binding var number: String
    let busy: Bool
    let onCreate: () -> Void

    private static let maxLength = 8
    private static let digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Order number")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)
                TextField("Order number", text: $number, prompt: Text(verbatim: "—"))
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .disabled(busy)
                    .onChange(of: number) { _, value in
                        if value.count > Self.maxLength { number = String(value.prefix(Self.maxLength)) }
                    }
            }
            .padding(.horizontal, 6)

            // A phone keypad reads left to right in every language.
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Self.digits, id: \.self) { digit in key(digit) }
                Button { number = "" } label: { keyLabel(Text(verbatim: "C")) }
                    .accessibilityLabel("Clear")
                key("0")
                Button { number = String(number.dropLast()) } label: { keyLabel(Image(systemName: "delete.backward")) }
                    .accessibilityLabel("Delete the last character")
            }
            .buttonStyle(.plain)
            .environment(\.layoutDirection, .leftToRight)
            .disabled(busy)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Number pad")

            Button(action: onCreate) {
                if busy {
                    ProgressView().tint(Theme.onAccent)
                } else {
                    Label("Show QR", systemImage: "qrcode")
                }
            }
            .buttonStyle(.waffiPrimary)
            .disabled(busy || number.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private func key(_ digit: String) -> some View {
        Button {
            if number.count < Self.maxLength { number += digit }
        } label: {
            keyLabel(Text(verbatim: digit))
        }
    }

    private func keyLabel(_ content: some View) -> some View {
        content
            .font(.title2.weight(.bold))
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
    }
}
