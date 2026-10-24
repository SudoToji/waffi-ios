import SwiftUI

/// Sign-in or the staff Pager, depending on the session. A ticket link (`https://<host>/p/<token>`) shows the ticket on top of either:
/// a person waiting who installed the app is not signed in, and needs no account.
struct RootView: View {
    @State private var session = SessionModel()
    @State private var ticket: PagerTicketModel?

    var body: some View {
        Group {
            switch session.state {
            case .starting:
                ProgressView()
            case .unreachable(let error):
                VStack(spacing: 16) {
                    Text(error.message).multilineTextAlignment(.center)
                    Button("Retry") { Task { await session.start() } }.buttonStyle(.borderedProminent)
                    Button("Sign out", role: .destructive) { Task { await session.signOut() } }
                }
                .padding(24)
            case .signedOut:
                SignInView(session: session)
            case .mustChangePassword:
                ChangePasswordView(session: session)
            case .signedIn(let account):
                NavigationStack { StaffPagerView(session: session, account: account) }
            }
        }
        .task { await session.start() }
        .fullScreenCover(item: $ticket) { model in
            NavigationStack {
                PagerTicketView(model: model)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { ticket = nil }
                        }
                    }
            }
        }
        // A scan of the same ticket again keeps what is on screen.
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL, let client = PagerClient(invocation: url) else { return }
            if ticket?.client.token != client.token { ticket = PagerTicketModel(client: client, host: .app) }
        }
    }
}
