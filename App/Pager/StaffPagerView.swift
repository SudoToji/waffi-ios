import SwiftUI

/// The staff Pager: Branch choice, number pad, the Waiting and Ready lists. Opens after sign-in.
struct StaffPagerView: View {
    let session: SessionModel
    let account: AppAccount
    @State private var model: StaffPagerModel
    @State private var showAbout = false

    init(session: SessionModel, account: AppAccount) {
        self.session = session
        self.account = account
        _model = State(initialValue: StaffPagerModel(api: session.api, userId: account.user.id))
    }

    var body: some View {
        content
            .navigationTitle("Pager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section(account.user.email) {
                            if model.branches.count > 1 {
                                Button("Change Branch", systemImage: "building.2") { model.changeBranch() }
                            }
                            Button("About", systemImage: "info.circle") { showAbout = true }
                            Button("Sign out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                                Task { await session.signOut() }
                            }
                        }
                    } label: {
                        Label("Account", systemImage: "person.crop.circle")
                    }
                }
            }
            .task { await model.load() }
            .sheet(isPresented: $showAbout) {
                NavigationStack { AboutView() }
            }
    }

    @ViewBuilder private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView()
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
            PagerBoardView(model: model)
        }
    }
}
