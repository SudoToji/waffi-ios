import SwiftUI

/// The staff Pager: Branch choice, number pad, the Waiting and Ready lists. Opens after sign-in.
struct StaffPagerView: View {
    let session: SessionModel
    let account: AppAccount
    @State private var model: StaffPagerModel
    @State private var showAccount = false

    init(session: SessionModel, account: AppAccount) {
        self.session = session
        self.account = account
        _model = State(initialValue: StaffPagerModel(api: session.api, userId: account.user.id))
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            content
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await model.load() }
        .sheet(isPresented: $showAccount) {
            NavigationStack { AccountView(session: session, account: account) }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Pager")
                    .font(.title.weight(.heavy))
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                branchLine
            }
            Spacer()
            accountMenu
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// "Business · Branch"; a button with a chevron when there is another Branch to switch to.
    @ViewBuilder private var branchLine: some View {
        if case .board = model.phase, let branch = model.branch {
            let place = "\(account.business.name) · \(branch.name)"
            if model.branches.count > 1 {
                Button { model.changeBranch() } label: {
                    HStack(spacing: 4) {
                        Text(verbatim: place)
                        Image(systemName: "chevron.down").font(.caption.weight(.heavy))
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)
                .accessibilityHint("Change Branch")
            } else {
                Text(verbatim: place)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var accountMenu: some View {
        Menu {
            Section(account.user.email) {
                if model.branches.count > 1 {
                    Button("Change Branch", systemImage: "building.2") { model.changeBranch() }
                }
                Button("Account", systemImage: "person.crop.circle") { showAccount = true }
                Button("Sign out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                    Task { await session.signOut() }
                }
            }
        } label: {
            Label("Account", systemImage: "person")
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.text)
                .frame(width: 44, height: 44)
                .background(Theme.card, in: .circle)
                .overlay(Circle().strokeBorder(Theme.border))
        }
    }

    @ViewBuilder private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView().frame(maxHeight: .infinity)
        case .failed:
            VStack(spacing: 16) {
                Text(model.loadError?.message ?? ApiError.network.message).multilineTextAlignment(.center)
                Button("Retry") { Task { await model.load() } }.buttonStyle(.borderedProminent)
            }
            .padding(24)
        case .off:
            ContentUnavailableView("The Pager is not turned on for your Business.", systemImage: "bell.slash")
        case .noBranch:
            ContentUnavailableView("No Branch is available. Ask the Owner to assign you to one.", systemImage: "building.2")
        case .choosing(let gone):
            BranchChoiceView(model: model, gone: gone)
        case .board:
            PagerBoardView(model: model, businessName: account.business.name)
        }
    }
}
