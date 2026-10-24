import SwiftUI

/// The Customers tab: the Business's people, searchable and filterable, and each one's page.
struct CustomersView: View {
    let session: SessionModel
    let account: AppAccount
    let tiersOn: Bool
    /// Opens the Earn & redeem tab on a Card (its Manual Code); nil when this role has no such tab.
    let openEarn: ((String) -> Void)?
    @State private var model: CustomersModel
    @State private var path: [String] = []
    @State private var showAdd = false

    init(session: SessionModel, account: AppAccount, tiersOn: Bool, openEarn: ((String) -> Void)?) {
        self.session = session
        self.account = account
        self.tiersOn = tiersOn
        self.openEarn = openEarn
        _model = State(
            initialValue: CustomersModel(api: session.api, tiersOn: tiersOn, canSetTier: account.user.may("customers.view")))
    }

    private var canManage: Bool { account.user.may("customers.view") }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header
                searchRow
                CustomerFilters(model: model)
                content
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Customers")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                if let customer = model.customer(id: id) {
                    CustomerDetailView(
                        customer: customer, session: session, account: account, tiersOn: tiersOn, openEarn: openEarn,
                        onChanged: { model.update($0) },
                        onDeleted: { model.remove(id: $0) })
                }
            }
        }
        .task { await model.loadSide() }
        .task(id: model.query) {
            // The website waits 300 ms after the last key; a chip or a sort reads at once.
            if model.query.search != model.loadedSearch {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
            }
            await model.reload()
        }
        .sheet(isPresented: $showAdd) {
            CustomerFormSheet(customer: nil) { form in
                let error = await model.create(form)
                if error == nil { await model.reload() }
                return error
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Customers")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                subtitle.font(.subheadline.weight(.semibold)).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            if canManage {
                Button { showAdd = true } label: {
                    Label("Add customer", systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 44, height: 44)
                        .background(Theme.card, in: .circle)
                        .overlay(Circle().strokeBorder(Theme.border))
                }
            }
            AccountButton(session: session, account: account)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    @ViewBuilder private var subtitle: some View {
        if let total = model.counts?.total {
            Text("\(total) in \(account.business.name)")
        } else {
            Text(verbatim: account.business.name)
        }
    }

    private var searchRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.secondaryText).accessibilityHidden(true)
                TextField("Name, phone or Manual Code", text: $model.search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .foregroundStyle(Theme.text)
                if !model.search.isEmpty {
                    Button { model.search = "" } label: {
                        Label("Clear", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(Theme.secondaryText)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border))
            sortMenu
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort customers", selection: $model.sort) {
                ForEach(model.sorts) { sort in Text(sort.title).tag(sort) }
            }
        } label: {
            Label("Sort customers", systemImage: "arrow.up.arrow.down")
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.text)
                .frame(width: 50, height: 50)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border))
        }
    }

    // MARK: Content

    @ViewBuilder private var content: some View {
        if model.customers.isEmpty {
            if model.loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = model.error {
                VStack(spacing: 16) {
                    Text(error.message).multilineTextAlignment(.center).foregroundStyle(Theme.text)
                    Button("Retry") { Task { await model.reload() } }.buttonStyle(.borderedProminent)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if model.filtered {
                ContentUnavailableView("No customers match these filters.", systemImage: "magnifyingglass")
            } else {
                ContentUnavailableView {
                    Label("No customers yet", systemImage: "person.2")
                } description: {
                    Text("Share your signup link and your first regular will appear here.")
                }
            }
        } else {
            list
        }
    }

    private var list: some View {
        ScrollView {
            if let error = model.error {
                Text(error.message).font(.subheadline).foregroundStyle(Theme.warning).padding(.horizontal, 16)
            }
            LazyVStack(spacing: 0) {
                ForEach(model.customers) { customer in
                    NavigationLink(value: customer.id) {
                        CustomerRow(customer: customer, showTier: tiersOn)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if customer.id == model.customers.last?.id { Task { await model.loadMore() } }
                    }
                    if customer.id != model.customers.last?.id {
                        Rectangle().fill(Theme.border).frame(height: 1 / 3).padding(.leading, 72)
                    }
                }
            }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            footer
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable { await model.refresh() }
    }

    @ViewBuilder private var footer: some View {
        if model.loadingMore {
            ProgressView().frame(maxWidth: .infinity).padding(16)
        } else if let error = model.moreError {
            VStack(spacing: 8) {
                Text(error.message).font(.subheadline).foregroundStyle(Theme.warning)
                Button("Retry") { Task { await model.loadMore() } }
            }
            .padding(16)
        } else {
            Color.clear.frame(height: 24)
        }
    }
}
