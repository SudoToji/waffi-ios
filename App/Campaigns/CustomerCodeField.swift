import SwiftUI

/// The "One customer" audience: the six-digit Manual Code, with the Customer's name shown as soon as the Card is found
/// (the website looks the Card up as the code is typed).
struct CustomerCodeField: View {
    let api: ApiClient
    @Binding var code: String
    @State private var name: String?
    @State private var error: ApiError?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Six-digit customer card number", text: $code)
                .keyboardType(.numberPad)
                .environment(\.layoutDirection, .leftToRight)
                .multilineTextAlignment(.leading)
                .waffiField()
                .onChange(of: code) {
                    let digits = String(code.filter(\.isASCII).filter(\.isNumber).prefix(6))
                    if digits != code { code = digits }
                }
            if let name {
                Label { Text(verbatim: name) } icon: { Image(systemName: "person.crop.circle.badge.checkmark") }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            } else if let error {
                Text(error.message).font(.footnote).foregroundStyle(Theme.warning)
            }
        }
        .task(id: code) {
            name = nil
            error = nil
            guard MessageForm.validCode(code) else { return }
            do {
                let card: StaffCard = try await api.get("api/loyalty/lookup", query: [URLQueryItem(name: "code", value: code)])
                name = card.customerName
            } catch let failure as ApiError {
                error = failure
            } catch {}
        }
    }
}
