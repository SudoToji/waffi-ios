import SwiftUI

/// Sign-in or the staff app, depending on the session. A ticket link (`https://<host>/p/<token>`) replaces the screen with the ticket
/// until it is closed: a person waiting who installed the app is not signed in, and needs no account. The ticket is not a presented
/// cover, because iOS silently refuses a cover while another one (the staff QR screen, a sheet) is up.
struct RootView: View {
    @State private var session = SessionModel()
    @State private var ticket: PagerTicketModel?
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.system

    var body: some View {
        Group {
            if let ticket {
                NavigationStack {
                    PagerTicketView(model: ticket)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { self.ticket = nil }
                            }
                        }
                }
            } else {
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
                    AppShell(session: session, account: account)
                }
            }
        }
        .tint(Theme.accent)
        // The ticket screen is always dark; everything else follows the Appearance chosen in Account.
        .preferredColorScheme(ticket != nil ? .dark : appearance.scheme)
        // The language chosen in Account, right to left for Arabic.
        .environment(\.locale, language.locale)
        .environment(\.layoutDirection, language.layoutDirection)
        .task { await session.start() }
        // iOS delivers a universal link as a browsing activity; a link opened another way arrives as a URL. Both open the ticket.
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            if let url = activity.webpageURL { open(url) }
        }
        .onOpenURL { open($0) }
    }

    /// A scan of the same ticket again keeps what is on screen.
    private func open(_ url: URL) {
        guard let client = PagerClient(invocation: url), ticket?.client.token != client.token else { return }
        ticket = PagerTicketModel(client: client, host: .app)
    }
}
