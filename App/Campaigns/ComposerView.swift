import SwiftUI

/// The composer (full screen): write, the draft saves itself, then Send now or Schedule for later.
struct ComposerView: View {
    @State private var model: ComposerModel
    let businessName: String
    /// Closes the composer; the text is a note for the list ("Sent to 186 Customers"), or nil.
    let onClose: (String?) -> Void
    @State private var confirming: SendModel?

    init(model: ComposerModel, businessName: String, onClose: @escaping (String?) -> Void) {
        _model = State(initialValue: model)
        self.businessName = businessName
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 14) {
                    MessageSection(model: model)
                    AudienceSection(model: model)
                    CouponSection(model: model)
                    LockPreview(business: businessName, form: model.form)
                    Text("Google Wallet shows at most 3 message alerts a day per card. After that, messages still arrive on the card, without an alert.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .disabled(model.locked)
            bottomBar
        }
        .background(Theme.background.ignoresSafeArea())
        .onChange(of: model.form) { model.edited() }
        .sheet(item: $confirming) { send in
            SendConfirmSheet(model: send, tiers: model.tiers, branches: model.branches) { recipients in
                model.sent()
                confirming = nil
                onClose(recipients.map { String(localized: "Sent to \($0) Customers") } ?? String(localized: "Message sent"))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(model.campaign == nil ? "New message" : "Edit draft")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                saveState
            }
            HStack {
                Button("Close") {
                    Task {
                        await model.finish()
                        onClose(nil)
                    }
                }
                .foregroundStyle(Theme.accent)
                .frame(minHeight: 44)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    @ViewBuilder private var saveState: some View {
        switch model.state {
        case .idle: EmptyView()
        case .waiting:
            Text("Not saved yet").font(.caption).foregroundStyle(Theme.secondaryText)
        case .saving:
            HStack(spacing: 4) {
                ProgressView().controlSize(.mini)
                Text("Saving…").font(.caption).foregroundStyle(Theme.secondaryText)
            }
        case .saved:
            Label("Saved", systemImage: "checkmark")
                .font(.caption)
                .foregroundStyle(Theme.accent)
        case .failed(let error):
            Button { model.retry() } label: {
                Text("\(error.message) Tap to try again.").font(.caption).foregroundStyle(Theme.warning).multilineTextAlignment(.center)
            }
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if let error = model.submitError {
                Text(error.message).font(.footnote).foregroundStyle(Theme.warning).multilineTextAlignment(.center)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            if !model.deliveryEnabled && !model.scheduling {
                Text("Delivery is paused. You can schedule a message, but it will not send until the platform admin switches delivery on.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            if model.scheduling { scheduleBar } else { sendBar }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Theme.background.shadow(.drop(color: .black.opacity(0.06), radius: 8, y: -2)))
    }

    private var sendBar: some View {
        VStack(spacing: 6) {
            Button {
                Task {
                    if let draft = await model.draftToSend() {
                        confirming = SendModel(api: model.api, source: .draft(draft), counts: model.counts)
                    }
                }
            } label: {
                if model.busy { ProgressView() } else if let recipients = model.recipients {
                    Text("Send now · \(recipients) Customers")
                } else {
                    Text("Send now")
                }
            }
            .buttonStyle(.waffiPrimary)
            .disabled(!model.form.isValid || model.busy || model.locked || !model.deliveryEnabled)
            Button { withAnimation { model.scheduling = true } } label: {
                Label("Schedule for later", systemImage: "clock")
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
            }
            .foregroundStyle(Theme.accent)
            .disabled(model.busy || model.locked)
        }
    }

    private var scheduleBar: some View {
        VStack(spacing: 6) {
            DatePicker(
                "Send on", selection: $model.scheduleAt,
                in: Date.now.addingTimeInterval(120)...Date.now.addingTimeInterval(364 * 86400)
            )
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            Text("Your time zone: \(TimeZone.current.identifier)").font(.footnote).foregroundStyle(Theme.secondaryText)
            Button {
                Task {
                    guard let result = await model.schedule() else { return }
                    let note = result.activateError == nil
                        ? String(localized: "Scheduled for \(model.scheduleAt.formatted(date: .abbreviated, time: .shortened))")
                        : String(localized: "Schedule saved. Activate delivery when you are ready.")
                    onClose(note)
                }
            } label: {
                if model.busy {
                    ProgressView()
                } else {
                    Text("Schedule · \(model.scheduleAt.formatted(date: .abbreviated, time: .shortened))")
                }
            }
            .buttonStyle(.waffiPrimary)
            .disabled(!model.form.isValid || model.busy || model.locked)
            Button { withAnimation { model.scheduling = false } } label: {
                Label("Send now instead", systemImage: "paperplane")
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
            }
            .foregroundStyle(Theme.accent)
            .disabled(model.busy)
        }
    }
}
