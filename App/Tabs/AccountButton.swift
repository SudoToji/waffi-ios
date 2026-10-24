import SwiftUI

/// The round account button of a tab's header: opens the account sheet (who is signed in, Sign out, privacy, support).
struct AccountButton: View {
    let session: SessionModel
    let account: AppAccount
    @State private var showAccount = false

    var body: some View {
        Button { showAccount = true } label: {
            Label("Account", systemImage: "person")
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.text)
                .frame(width: 44, height: 44)
                .background(Theme.card, in: .circle)
                .overlay(Circle().strokeBorder(Theme.border))
        }
        .sheet(isPresented: $showAccount) {
            NavigationStack { AccountView(session: session, account: account) }
        }
    }
}
