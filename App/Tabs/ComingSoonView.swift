import SwiftUI

/// A tab whose screens are built in a later ticket; also the notice for a Staff Member whose access opens no tab (`tab` nil).
struct ComingSoonView: View {
    let tab: AppTab?
    let session: SessionModel
    let account: AppAccount

    var body: some View {
        VStack {
            HStack {
                Spacer()
                AccountButton(session: session, account: account)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            if let tab {
                ContentUnavailableView {
                    Label(tab.title, systemImage: tab.systemImage)
                } description: {
                    Text("Coming soon")
                }
            } else {
                ContentUnavailableView(
                    "Nothing is available to your account yet. Ask the Owner to change your access.", systemImage: "lock")
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.background.ignoresSafeArea())
    }
}
