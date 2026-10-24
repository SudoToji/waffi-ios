import SwiftUI

/// The Owner's and Manager's Overview: the website dashboard's numbers and the newest activity, for all Branches or one.
struct OverviewView: View {
    let session: SessionModel
    let account: AppAccount
    @State private var model: OverviewModel
    /// The chosen Branch id; nil is All Branches.
    @State private var branch: String?

    init(session: SessionModel, account: AppAccount) {
        self.session = session
        self.account = account
        _model = State(initialValue: OverviewModel(api: session.api))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                titleRow
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.background.ignoresSafeArea())
        .refreshable { await model.load(branch: branch, reset: false) }
        // A new Branch drops the old numbers first; the first run is the same.
        .task(id: branch) { await model.load(branch: branch, reset: true) }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                greeting.font(.subheadline).foregroundStyle(Theme.secondaryText)
                branchPicker
            }
            Spacer()
            AccountButton(session: session, account: account)
        }
        .padding(.top, 8)
    }

    private var greeting: Text {
        let name = account.user.fullName?.split(separator: " ").first.map(String.init) ?? account.business.name
        switch Calendar.current.component(.hour, from: .now) {
        case ..<12: return Text("Good morning, \(name)")
        case ..<18: return Text("Good afternoon, \(name)")
        default: return Text("Good evening, \(name)")
        }
    }

    /// "Business · Branch"; a menu when the Business has more than one Branch.
    @ViewBuilder private var branchPicker: some View {
        let current = model.branches.first { $0.id == branch }
        let place = "\(account.business.name) · \(current.map(label) ?? String(localized: "All branches"))"
        if model.branches.count > 1 {
            Menu {
                Picker("Branch", selection: $branch) {
                    Text("All branches").tag(String?.none)
                    ForEach(model.branches) { Text(verbatim: label($0)).tag(String?.some($0.id)) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(verbatim: place).multilineTextAlignment(.leading)
                    Image(systemName: "chevron.down").font(.caption.weight(.heavy))
                }
                .font(.headline.weight(.semibold))
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .foregroundStyle(Theme.text)
            .accessibilityLabel(Text("Branch"))
            .accessibilityValue(Text(verbatim: place))
        } else {
            Text(verbatim: place).font(.headline.weight(.semibold)).foregroundStyle(Theme.text)
        }
    }

    /// A closed or Locked Branch is marked, as on the website.
    private func label(_ branch: StaffBranch) -> String {
        switch branch.status {
        case "closed": String(localized: "\(branch.name) (closed)")
        case "locked": String(localized: "\(branch.name) (Locked)")
        default: branch.name
        }
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Overview")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: Body

    @ViewBuilder private var content: some View {
        if let error = model.error, model.analytics == nil {
            VStack(spacing: 16) {
                Text(error.message).multilineTextAlignment(.center).foregroundStyle(Theme.text)
                Button("Retry") { Task { await model.load(branch: branch, reset: true) } }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        } else {
            if let error = model.error {
                Text(error.message).font(.footnote).foregroundStyle(Theme.warning)
            }
            OverviewHero(analytics: model.analytics ?? .placeholder)
                .redacted(reason: model.analytics == nil ? .placeholder : [])
            ActivityList(rows: model.activity, failed: model.activityFailed)
        }
    }
}
