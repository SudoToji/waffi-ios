import SwiftUI

/// Sign-in or the staff Pager, depending on the session. A ticket link (`https://<host>/p/<token>`) shows the ticket on top of either:
/// a person waiting who installed the app is not signed in, and needs no account.
struct RootView: View {
    @State private var session = SessionModel()
    @State private var ticket: PagerTicketModel?
    /// Changed when a ticket link arrives: rebuilding the shell closes whatever it presents (the QR screen, a sheet),
    /// since iOS will not show the ticket over another full-screen presentation.
    @State private var shellID = UUID()

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
                AppShell(session: session, account: account).id(shellID)
            }
        }
        .tint(Theme.accent)
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
            guard ticket?.client.token != client.token else { return }
            ticket = nil
            shellID = UUID()
            Task { @MainActor in
                // Let the closed presentations finish dismissing before the ticket is shown.
                try? await Task.sleep(for: .milliseconds(450))
                ticket = PagerTicketModel(client: client, host: .app)
            }
        }
    }
}
