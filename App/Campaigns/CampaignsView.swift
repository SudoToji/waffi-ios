import SwiftUI

/// The Campaigns tab (the Owner's "Messages"): write a message, it saves itself, Send now; send it again in one tap.
struct CampaignsView: View {
    /// A change that asks for a confirmation first.
    private enum Change: Identifiable {
        case cancel(Campaign), stop(Campaign), delete(Campaign)

        var id: String {
            switch self {
            case .cancel(let campaign): "cancel-" + campaign.id
            case .stop(let campaign): "stop-" + campaign.id
            case .delete(let campaign): "delete-" + campaign.id
            }
        }
    }

    private struct ComposerRoute: Identifiable {
        let id = UUID()
        let model: ComposerModel
    }

    let session: SessionModel
    let account: AppAccount
    @State private var model: CampaignsModel
    @State private var composer: ComposerRoute?
    @State private var confirm: SendModel?
    @State private var results: SavedMessage?
    @State private var change: Change?
    @State private var toast: String?

    init(session: SessionModel, account: AppAccount, tiersOn: Bool) {
        self.session = session
        self.account = account
        _model = State(initialValue: CampaignsModel(api: session.api, tiersOn: tiersOn))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Theme.background.ignoresSafeArea())
        .overlay(alignment: .bottom) { toastView }
        .task { await model.load() }
        .fullScreenCover(item: $composer) { route in
            ComposerView(model: route.model, businessName: account.business.name) { note in
                composer = nil
                if let note { toast = note }
                Task { await model.load() }
            }
        }
        .sheet(item: $confirm) { send in
            SendConfirmSheet(model: send, tiers: model.tiers, branches: model.branches) { recipients in
                confirm = nil
                toast = recipients.map { String(localized: "Sent to \($0) Customers") } ?? String(localized: "Message sent")
                Task { await model.load() }
            }
        }
        .sheet(item: $results) { message in
            ResultsSheet(message: message, counts: model.results(message))
        }
        .confirmationDialog(
            changeTitle, isPresented: Binding(get: { change != nil }, set: { if !$0 { change = nil } }),
            titleVisibility: .visible, presenting: change
        ) { item in
            switch item {
            case .cancel(let campaign):
                Button("Return to drafts", role: .destructive) { Task { if await model.cancelSchedule(campaign) { toast = String(localized: "Schedule cancelled. Your message is back in drafts.") } } }
            case .stop(let campaign):
                Button("Stop sending", role: .destructive) { Task { if await model.stop(campaign) { toast = String(localized: "Campaign stopped. Messages not sent yet were skipped.") } } }
            case .delete(let campaign):
                Button("Delete", role: .destructive) { Task { if await model.deleteDraft(campaign) { toast = String(localized: "Campaign deleted.") } } }
            }
            Button("Go back", role: .cancel) {}
        } message: { item in
            switch item {
            case .cancel: Text("Your message returns to drafts so you can edit it or choose another time.")
            case .stop: Text("Messages not sent yet are skipped. Messages already sent cannot be taken back.")
            case .delete: Text("This campaign will disappear from your lists and activity. Coupons already sent stay valid.")
            }
        }
    }

    private var changeTitle: LocalizedStringKey {
        switch change {
        case .cancel: "Cancel this schedule?"
        case .stop: "Stop sending this campaign?"
        case .delete: "Delete campaign?"
        case nil: ""
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Messages")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: account.business.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            AccountButton(session: session, account: account)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: Content

    @ViewBuilder private var content: some View {
        if model.loading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = model.error, model.isEmpty {
            VStack(spacing: 16) {
                Text(error.message).multilineTextAlignment(.center).foregroundStyle(Theme.text)
                Button("Retry") { Task { await model.load() } }.buttonStyle(.borderedProminent)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            list
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                Button { openComposer(form: MessageForm(locale: phoneLanguage), draft: nil) } label: {
                    Label("New message", systemImage: "plus")
                }
                .buttonStyle(.waffiPrimary)
                if let error = model.actionError ?? model.error {
                    Text(error.message).font(.subheadline).foregroundStyle(Theme.warning).accessibilityAddTraits(.updatesFrequently)
                }
                if model.isEmpty {
                    ContentUnavailableView {
                        Label("No messages yet", systemImage: "megaphone")
                    } description: {
                        Text("Write your first message. It saves itself, and you can send it again any time.")
                    }
                }
                if !(model.messages.isEmpty && model.drafts.isEmpty) { heading("Saved messages") }
                ForEach(model.messages) { message in
                    SavedMessageCard(
                        message: message, delivered: model.delivered(message), tiers: model.tiers, branches: model.branches,
                        disabled: model.busy,
                        onAgain: { confirm = SendModel(api: session.api, source: .again(message.latest)) },
                        onEdit: { openComposer(form: MessageForm(message.latest, fresh: true), draft: nil) },
                        onResults: { results = message },
                        onStop: { if let sending = message.sending { change = .stop(sending) } })
                }
                if model.hasMoreSent {
                    Button("Show older messages") { Task { await model.loadMoreSent() } }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(Theme.accent)
                        .disabled(model.loadingMore)
                }
                ForEach(model.drafts) { draft in
                    DraftCard(
                        draft: draft, tiers: model.tiers, branches: model.branches, disabled: model.busy,
                        sendEnabled: model.deliveryEnabled,
                        onEdit: { openComposer(form: MessageForm(draft), draft: draft) },
                        onSend: { confirm = SendModel(api: session.api, source: .draft(draft)) },
                        onDelete: { change = .delete(draft) })
                }
                if !model.scheduled.isEmpty { heading("Scheduled") }
                ForEach(model.scheduled) { campaign in
                    ScheduledRow(
                        campaign: campaign, tiers: model.tiers, branches: model.branches, disabled: model.busy,
                        activateEnabled: model.deliveryEnabled,
                        onCancel: { change = .cancel(campaign) },
                        onActivate: { Task { if await model.activate(campaign) { toast = String(localized: "Delivery activated for the scheduled time.") } } })
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .refreshable { await model.load() }
    }

    private func heading(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Theme.secondaryText)
            .padding(.top, 4)
            .accessibilityAddTraits(.isHeader)
    }

    /// New messages start in the phone's language, as the website starts in the interface language.
    private var phoneLanguage: String {
        Locale.current.language.languageCode?.identifier == "ar" ? "ar" : "en"
    }

    private func openComposer(form: MessageForm, draft: Campaign?) {
        composer = ComposerRoute(
            model: ComposerModel(
                api: session.api, form: form, draft: draft, tiersOn: model.tiersOn, tiers: model.tiers,
                branches: model.branches, deliveryEnabled: model.deliveryEnabled))
    }

    // MARK: Toast

    @ViewBuilder private var toastView: some View {
        if let toast {
            Label { Text(verbatim: toast) } icon: { Image(systemName: "checkmark.circle.fill") }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                .background(Color(red: 0.11, green: 0.13, blue: 0.12), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: toast) {
                    AccessibilityNotification.Announcement(toast).post()
                    try? await Task.sleep(for: .seconds(3.5))
                    withAnimation { self.toast = nil }
                }
        }
    }
}
