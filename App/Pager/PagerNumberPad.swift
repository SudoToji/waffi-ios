import SwiftUI

/// The order number as typed or tapped. Letters come from the keyboard; the pad is the fast path for digits.
struct PagerNumberPad: View {
    @Binding var number: String
    let busy: Bool
    let onCreate: () -> Void

    private static let maxLength = 8
    private static let digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 12) {
            TextField("Order number", text: $number)
                .font(.system(.title, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .textFieldStyle(.roundedBorder)
                .environment(\.layoutDirection, .leftToRight)
                .disabled(busy)
                .onChange(of: number) { _, value in
                    if value.count > Self.maxLength { number = String(value.prefix(Self.maxLength)) }
                }
            Text("Up to 8 letters or numbers").font(.footnote).foregroundStyle(.secondary)

            // A phone keypad reads left to right in every language.
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Self.digits, id: \.self) { digit in key(digit) }
                Button("Clear") { number = "" }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, minHeight: 52)
                key("0")
                Button("Delete the last character", systemImage: "delete.backward") { number = String(number.dropLast()) }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .environment(\.layoutDirection, .leftToRight)
            .disabled(busy)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Number pad")

            Button(action: onCreate) {
                if busy { ProgressView() } else { Text("New ticket").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(busy || number.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func key(_ digit: String) -> some View {
        Button {
            if number.count < Self.maxLength { number += digit }
        } label: {
            Text(digit).font(.title2.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.bordered)
    }
}
