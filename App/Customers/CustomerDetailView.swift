import SwiftUI

/// What the "Actions" menu asks to confirm.
private enum CustomerConfirmation {
    case link, cutOff, delete, cutOffDone
}

/// A Customer's page: who they are, their figures, Cards and latest Transactions, the actions the role may take,
/// and "Earn & redeem" for their Card.
struct CustomerDetailView: View {
    let openEarn: ((String) -> Void)?
    let onChanged: (Customer) -> Void
    let onDeleted: (String) -> Void
    @State private var model: CustomerDetailModel
    @State private var confirmation: CustomerConfirmation?
    @State private var showEdit = false
    @State private var showLink = false
    @State private var pendingTier: CustomerTier?
    @Environment(\.dismiss) private var dismiss

    init(
        customer: Customer, session: SessionModel, account: AppAccount, tiersOn: Bool, openEarn: ((String) -> Void)?,
        onChanged: @escaping (Customer) -> Void, onDeleted: @escaping (String) -> Void
    ) {
        self.openEarn = openEarn
        self.onChanged = onChanged
        self.onDeleted = onDeleted
        _model = State(
            initialValue: CustomerDetailModel(customer: customer, api: session.api, account: account, tiersOn: tiersOn))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let error = model.actionError, !showEdit {
                    Text(error.message).font(.subheadline).foregroundStyle(Theme.warning)
                        .accessibilityAddTraits(.updatesFrequently)
                }
                CustomerHeader(customer: model.customer, showTier: model.tiersOn)
                if model.tiersOn { tierRow }
                if model.tiersOn, figuresQuiet { quietFlag }
                CustomerStats(
                    customer: model.customer, figures: model.figures, error: model.figuresError,
                    showTierRecord: model.tiersOn && model.canManage, retry: { Task { await model.loadFigures() } })
                CustomerCardsSection(cards: model.customer.cards, cardTiers: model.cardTiers)
                if let figures = model.figures {
                    GiftsChart(months: figures.months, period: $model.period)
                    CustomerHistorySection(history: figures.history)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if model.canManage {
                ToolbarItem(placement: .primaryAction) { actionsMenu }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let openEarn, !model.customer.activeCards.isEmpty {
                EarnButton(cards: model.customer.activeCards, open: openEarn)
            }
        }
        .overlay {
            if model.busy {
                ProgressView().controlSize(.large).padding(24).background(.regularMaterial, in: .rect(cornerRadius: 16))
            }
        }
        .task { await model.load() }
        .task(id: model.period) { await model.loadFigures() }
        .onChange(of: model.customer) { onChanged(model.customer) }
        .alert(
            confirmation.map(Self.title) ?? "", isPresented: confirmationBinding, presenting: confirmation,
            actions: { item in confirmationActions(item) },
            message: { item in Text(message(for: item)) }
        )
        .sheet(isPresented: $showEdit) {
            CustomerFormSheet(customer: model.customer) { form in
                _ = await model.save(form)
                return model.actionError
            }
        }
        .sheet(isPresented: $showLink, onDismiss: { model.closeLink() }) {
            CardLinkSheet(model: model)
        }
        .sheet(item: $pendingTier) { tier in
            TierAssignSheet(model: model, tier: tier)
        }
    }

    // MARK: Tier

    private var figuresQuiet: Bool { model.figures?.quiet ?? model.customer.isQuiet }

    private var quietFlag: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.zzz").foregroundStyle(Theme.warning).accessibilityHidden(true)
            Text("No visit for 10 days").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
            Spacer(minLength: 8)
            if model.canSetTier {
                Button("Dismiss") { Task { await model.dismissQuiet() } }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.accent)
                    .frame(minHeight: 44)
                    .disabled(model.busy)
                    .accessibilityLabel(Text("Dismiss the no-visit flag for \(model.customer.name)"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Theme.warning.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
    }

    /// "Customer tier": the tier held, and for whoever may set tiers a menu to change it.
    private var tierRow: some View {
        HStack(spacing: 12) {
            Text("Customer tier").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.secondaryText)
            Spacer(minLength: 8)
            if model.canSetTier {
                Menu {
                    Picker("Customer tier", selection: tierSelection) {
                        Text("No tier yet").tag("")
                        ForEach(model.tiers) { Text(verbatim: $0.displayName).tag($0.id) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(verbatim: model.customer.customerTier?.displayName ?? String(localized: "No tier yet"))
                        Image(systemName: "chevron.up.chevron.down").font(.caption.weight(.bold)).accessibilityHidden(true)
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.accent)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .disabled(model.busy)
                .accessibilityLabel(Text("Assign tier for \(model.customer.name)"))
            } else if let tier = model.customer.customerTier {
                TierBadge(tier: tier)
                if model.customer.manualTier == true {
                    Text("Set by hand").font(.caption).foregroundStyle(Theme.secondaryText)
                }
            } else {
                Text("No tier yet").font(.subheadline.weight(.bold)).foregroundStyle(Theme.text)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    /// The tier held by hand (a tier the Business gave by itself shows as "No tier yet" in the menu, as on the website).
    private var tierSelection: Binding<String> {
        Binding(
            get: { model.customer.manualTier == true ? model.customer.customerTier?.id ?? "" : "" },
            set: { chooseTier($0) })
    }

    /// A higher tier asks first whether to tell the Customer; a lower one, or none, applies at once.
    private func chooseTier(_ id: String) {
        let chosen = model.tiers.first { $0.id == id }
        let held = model.customer.customerTier
        if let chosen, held == nil || chosen.rank > (held?.rank ?? 0) {
            model.actionError = nil
            pendingTier = chosen
        } else {
            Task { _ = await model.assignTier(chosen, tellCustomer: nil) }
        }
    }

    // MARK: Actions

    private var actionsMenu: some View {
        Menu {
            Button("Edit customer", systemImage: "pencil") {
                model.actionError = nil
                showEdit = true
            }
            Button("Card link", systemImage: "link") { confirmation = .link }
            if !model.customer.cards.isEmpty {
                Button("Cut off Apple pass", systemImage: "iphone.slash") { confirmation = .cutOff }
            }
            Button("Delete customer", systemImage: "trash", role: .destructive) { confirmation = .delete }
        } label: {
            Label("Actions", systemImage: "ellipsis.circle")
        }
        .disabled(model.busy)
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(get: { confirmation != nil }, set: { if !$0 { confirmation = nil } })
    }

    private static func title(_ item: CustomerConfirmation) -> String {
        switch item {
        case .link: String(localized: "Card link")
        case .cutOff, .cutOffDone: String(localized: "Cut off Apple pass")
        case .delete: String(localized: "Delete customer")
        }
    }

    @ViewBuilder private func confirmationActions(_ item: CustomerConfirmation) -> some View {
        switch item {
        case .link:
            Button("Create link") {
                Task { if await model.issueLink() { showLink = true } }
            }
        case .cutOff:
            Button("Cut off Apple pass", role: .destructive) {
                Task { if await model.cutOffPass() { confirmation = .cutOffDone } }
            }
        case .delete:
            Button("Delete customer", role: .destructive) {
                Task {
                    let id = model.customer.id
                    if await model.delete() {
                        onDeleted(id)
                        dismiss()
                    }
                }
            }
        case .cutOffDone:
            Button("Done") {}
        }
        if item != .cutOffDone { Button("Cancel", role: .cancel) {} }
    }

    private func message(for item: CustomerConfirmation) -> String {
        let name = model.customer.name
        switch item {
        case .link:
            return model.customer.cardCount > 0
                ? String(
                    localized:
                        "This gives \(name) a new private link to their card. The link they have now stops working, and so does their Apple pass, which shows as no longer valid; they can add a new one from the new link. Their points and card number stay the same."
                )
                : String(localized: "\(name) has no card yet. This creates their card and a private link that opens it.")
        case .cutOff:
            return String(
                localized:
                    "The Apple pass on \(name)'s phone will stop working and show as no longer valid. Their card, its balance and its link stay as they are, and \(name) can add a new pass from their card page."
            )
        case .cutOffDone:
            return String(localized: "The Apple pass was cut off. \(name) can add a new pass from their card page.")
        case .delete:
            return String(
                localized:
                    "Delete \(name) and their linked cards and transaction history? This cannot be undone. A pass already saved on a phone may remain visible, but it will no longer work in Waffi. An anonymous copy of their Apple pass (no name, card or balance) is kept for 30 days so the pass on their phone can show as no longer valid."
            )
        }
    }
}
