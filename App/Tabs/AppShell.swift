import SwiftUI

/// What a signed-in person sees: the tabs their role, permissions and Business's Feature switches allow.
struct AppShell: View {
    let session: SessionModel
    let account: AppAccount
    /// `GET /api/addons`; nil until the first answer, like the website, where every feature reads as off until then.
    @State private var features: [String: Bool]?
    @State private var loadError: ApiError?
    @State private var selection = AppTab.overview
    /// A Manual Code a Customer's page asks the Earn & redeem tab to open.
    @State private var earnCode: String?
    @Environment(\.scenePhase) private var scenePhase

    private var tabs: [AppTab] { AppTab.visible(for: account.user, features: features ?? [:]) }

    var body: some View {
        Group {
            if features != nil {
                shell
            } else if let loadError {
                VStack(spacing: 16) {
                    Text(loadError.message).multilineTextAlignment(.center)
                    Button("Retry") { Task { await loadFeatures() } }.buttonStyle(.borderedProminent)
                    Button("Sign out", role: .destructive) { Task { await session.signOut() } }
                }
                .padding(24)
            } else {
                ProgressView()
            }
        }
        .task { await loadFeatures() }
        // The website reads the switches again when the window regains focus.
        .onChange(of: scenePhase) {
            if scenePhase == .active, features != nil { Task { await loadFeatures() } }
        }
    }

    @ViewBuilder private var shell: some View {
        if tabs.isEmpty {
            ComingSoonView(tab: nil, session: session, account: account)
        } else {
            TabView(selection: $selection) {
                ForEach(tabs) { tab in
                    content(for: tab)
                        .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                        .tag(tab)
                }
            }
            .onChange(of: tabs, initial: true) {
                if !tabs.contains(selection), let first = tabs.first { selection = first }
            }
        }
    }

    @ViewBuilder private func content(for tab: AppTab) -> some View {
        switch tab {
        case .overview: OverviewView(session: session, account: account)
        case .pager: NavigationStack { StaffPagerView(session: session, account: account) }
        case .earn: EarnView(session: session, account: account, openCode: $earnCode)
        case .customers:
            CustomersView(
                session: session, account: account, tiersOn: features?["customer_tiers"] == true,
                openEarn: earnOpener
            )
            // The Customer Tiers switch is read again on foreground; the tab starts over when it flips.
            .id(features?["customer_tiers"] == true)
        case .campaigns:
            CampaignsView(session: session, account: account, tiersOn: features?["customer_tiers"] == true)
                .id(features?["customer_tiers"] == true)
        }
    }

    /// Handed to the Customers tab only when this person has the Earn & redeem tab to open.
    private var earnOpener: ((String) -> Void)? {
        guard tabs.contains(.earn) else { return nil }
        return { code in openEarn(code) }
    }

    private func openEarn(_ code: String) {
        earnCode = code
        selection = .earn
    }

    private func loadFeatures() async {
        do {
            features = try await session.api.get("api/addons")
            loadError = nil
        } catch let error as ApiError {
            // A failed re-read keeps what was last known.
            if features == nil { loadError = error }
        } catch {}
    }
}
