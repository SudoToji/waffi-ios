import SwiftUI

/// The Earn & redeem tab: find the Customer's Card (camera, search, Manual Code), then earn or redeem on it.
struct EarnView: View {
    let session: SessionModel
    let account: AppAccount
    /// A Manual Code another tab asks to open (a Customer's page); read once, then cleared.
    @Binding var openCode: String?
    @State private var model: EarnModel

    init(session: SessionModel, account: AppAccount, openCode: Binding<String?>) {
        self.session = session
        self.account = account
        _openCode = openCode
        _model = State(initialValue: EarnModel(api: session.api, account: account))
    }

    var body: some View {
        content
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Theme.background.ignoresSafeArea())
            .task { await model.load() }
            .onChange(of: openCode, initial: true) {
                guard let code = openCode else { return }
                openCode = nil
                Task { await model.lookup(code) }
            }
            .sensoryFeedback(.success, trigger: model.successCount)
            .sensoryFeedback(.error, trigger: model.failureCount)
            .sheet(item: draftBinding) { draft in
                ConfirmSheet(model: model, draft: draft)
            }
    }

    /// The sheet closing by a swipe cancels the draft.
    private var draftBinding: Binding<OperationDraft?> {
        Binding(get: { model.draft }, set: { if $0 == nil { model.cancelDraft() } })
    }

    @ViewBuilder private var content: some View {
        switch model.phase {
        case .loading:
            VStack(spacing: 0) {
                EarnHeader(model: model, session: session, account: account).padding(.horizontal, 16)
                ProgressView().frame(maxHeight: .infinity)
            }
        case .failed:
            VStack(spacing: 16) {
                Text(model.loadError?.message ?? ApiError.network.message).multilineTextAlignment(.center)
                Button("Retry") { Task { await model.load() } }.buttonStyle(.borderedProminent)
            }
            .padding(24)
            .frame(maxHeight: .infinity)
        case .choosing(let gone):
            BranchChooser(model: model, gone: gone)
        case .ready:
            if model.card != nil {
                CardScreen(model: model)
            } else {
                FindScreen(model: model, session: session, account: account)
            }
        }
    }
}

/// "Earn & redeem" with "Business · Branch" under it (a menu when there is another Branch to switch to), and the account button.
struct EarnHeader: View {
    let model: EarnModel
    let session: SessionModel
    let account: AppAccount

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Earn & redeem")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                branchLine
            }
            Spacer()
            AccountButton(session: session, account: account)
        }
        .padding(.top, 8)
    }

    @ViewBuilder private var branchLine: some View {
        let place = model.branch.map { "\(account.business.name) · \($0.name)" } ?? account.business.name
        if model.branches.count > 1 {
            Button { model.changeBranch() } label: {
                HStack(spacing: 4) {
                    Text(verbatim: place).multilineTextAlignment(.leading)
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

/// "Where are you working today?": shown while several Branches are usable and none is chosen.
private struct BranchChooser: View {
    let model: EarnModel
    let gone: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Where are you working today?")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                Text("Choose the Branch you serve at. You can change it any time.").foregroundStyle(Theme.secondaryText)
                if gone {
                    Text("The Branch you were serving at is no longer available. Choose another.").foregroundStyle(Theme.warning)
                }
                ForEach(model.branches) { branch in
                    Button(branch.name) { model.choose(branch) }
                        .buttonStyle(.waffiTinted)
                }
            }
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
    }
}
