import Foundation
import Observation

/// The composer: the message saves itself. The draft is made with an app-made UUID once the message can be saved
/// (`POST /api/campaigns`), then every pause in typing sends the fields with the version read (`PUT /api/campaigns/:id`).
@Observable @MainActor
final class ComposerModel {
    enum SaveState: Equatable {
        /// Nothing to save yet.
        case idle
        /// Changes the draft does not hold yet (a pause is coming, or the message is not complete).
        case waiting
        case saving
        case saved
        case failed(ApiError)
    }

    /// How a schedule ended: `activateError` is set when it is saved but delivery could not be armed.
    struct Scheduled {
        let activateError: ApiError?
    }

    let api: ApiClient
    let tiersOn: Bool
    let tiers: [CustomerTier]
    let branches: [StaffBranch]
    let deliveryEnabled: Bool

    var form: MessageForm
    var scheduleAt = Date.now.addingTimeInterval(3600)
    var scheduling = false

    private(set) var campaign: Campaign?
    private(set) var state = SaveState.idle
    private(set) var counts: CampaignCounts?
    private(set) var countError: ApiError?
    private(set) var countLoading = false
    private(set) var busy = false
    private(set) var submitError: ApiError?
    /// The draft is gone or was sent: nothing more can be saved to it.
    private(set) var locked = false

    private var savedForm: MessageForm?
    private var creationId = UUID().uuidString.lowercased()
    private var saving = false
    private var saveTask: Task<Void, Never>?
    private var countTask: Task<Void, Never>?
    private var countedQuery: [URLQueryItem]?

    /// `draft`: an existing draft to keep editing; nil starts a message (`form` may be a copy of a sent one).
    init(api: ApiClient, form: MessageForm, draft: Campaign?, tiersOn: Bool, tiers: [CustomerTier], branches: [StaffBranch], deliveryEnabled: Bool) {
        self.api = api
        self.form = form
        self.tiersOn = tiersOn
        self.tiers = tiers
        self.branches = branches
        self.deliveryEnabled = deliveryEnabled
        campaign = draft
        if draft != nil {
            savedForm = form
            state = .saved
        }
        refreshCounts()
    }

    var recipients: Int? { counts?.optedIn }

    // MARK: Autosave

    /// Called on every change of the form.
    func edited() {
        refreshCounts()
        guard !locked, form != savedForm else { return }
        submitError = nil
        guard form.isValid else {
            saveTask?.cancel()
            state = .waiting
            return
        }
        state = .waiting
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await self?.performSave()
        }
    }

    /// Save now (a tap on the failed indicator).
    func retry() {
        saveTask?.cancel()
        Task { await performSave() }
    }

    /// Saves what is pending and says whether the draft now holds the whole form.
    func flush() async -> Bool {
        saveTask?.cancel()
        await performSave()
        return campaign != nil && form == savedForm && !locked
    }

    private func performSave(retriedCreate: Bool = false) async {
        while saving { try? await Task.sleep(for: .milliseconds(80)) }
        guard !locked, form != savedForm, form.isValid else { return }
        saving = true
        state = .saving
        defer { saving = false }
        let snapshot = form
        do {
            let result: Campaign
            if let campaign {
                result = try await api.put("api/campaigns/\(campaign.id)", json: snapshot.request(version: campaign.version))
            } else {
                result = try await api.post("api/campaigns", json: snapshot.request(id: creationId))
            }
            campaign = result
            savedForm = snapshot
            if form == snapshot {
                state = .saved
            } else {
                edited()
            }
        } catch let failure as ApiError {
            await failed(failure, retriedCreate: retriedCreate)
        } catch {
            state = .waiting
        }
    }

    /// `CAMPAIGN_CHANGED`: the draft moved on somewhere else. Read it again and show what it holds now.
    private func failed(_ failure: ApiError, retriedCreate: Bool) async {
        guard failure.code == "CAMPAIGN_CHANGED" else {
            if failure.code == "CAMPAIGN_NOT_FOUND" { locked = true }
            state = .failed(failure)
            return
        }
        guard let current = campaign else {
            // The id was used for other content: a new id makes a new draft.
            creationId = UUID().uuidString.lowercased()
            if retriedCreate { state = .failed(failure) } else {
                saving = false
                await performSave(retriedCreate: true)
            }
            return
        }
        do {
            let report: DeliveryReport = try await api.get(
                "api/campaigns/\(current.id)/deliveries", query: [URLQueryItem(name: "page", value: "1")])
            if report.campaign.status == "draft" {
                campaign = report.campaign
                let fresh = MessageForm(report.campaign)
                savedForm = fresh
                form = fresh
            } else {
                locked = true
            }
        } catch {
            locked = true
        }
        state = .failed(failure)
    }

    // MARK: Audience count

    /// The count follows the audience's choices, after a short pause (the API allows 30 a minute).
    private func refreshCounts() {
        guard form.audienceReady else {
            countTask?.cancel()
            counts = nil
            countError = nil
            countedQuery = nil
            countLoading = false
            return
        }
        let query = form.audienceQuery
        guard query != countedQuery else { return }
        countedQuery = query
        countTask?.cancel()
        countLoading = true
        countTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await self?.loadCounts(query)
        }
    }

    private func loadCounts(_ query: [URLQueryItem]) async {
        do {
            let fresh: CampaignCounts = try await api.get("api/campaigns/audience", query: query)
            guard query == countedQuery else { return }
            counts = fresh
            countError = nil
        } catch let failure as ApiError {
            guard query == countedQuery else { return }
            countError = failure
            countedQuery = nil
        } catch {}
        if query == countedQuery || countedQuery == nil { countLoading = false }
    }

    // MARK: Send and schedule

    /// The draft the send confirmation is for: saved first, so what is confirmed is what is sent. Nil when it could not be saved.
    func draftToSend() async -> Campaign? {
        guard !busy else { return nil }
        busy = true
        defer { busy = false }
        submitError = nil
        guard await flush(), let campaign else {
            if case .failed(let failure) = state { submitError = failure } else if !form.isValid { submitError = ApiError(code: "VALIDATION") }
            return nil
        }
        return campaign
    }

    /// The draft was sent: it cannot be edited any more.
    func sent() {
        locked = true
        saveTask?.cancel()
    }

    /// Saves the draft, schedules it, and arms delivery (the website's separate Activate step) when delivery is on.
    func schedule() async -> Scheduled? {
        guard !busy else { return nil }
        busy = true
        defer { busy = false }
        submitError = nil
        guard scheduleAt >= Date.now.addingTimeInterval(60), scheduleAt <= Date.now.addingTimeInterval(365 * 86400) else {
            submitError = ApiError(code: "CAMPAIGN_SCHEDULE_INVALID")
            return nil
        }
        guard await flush(), let draft = campaign else {
            if case .failed(let failure) = state { submitError = failure } else if !form.isValid { submitError = ApiError(code: "VALIDATION") }
            return nil
        }
        do {
            let result: Campaign = try await api.post("api/campaigns/\(draft.id)/schedule", json: ScheduleBody(version: draft.version, at: scheduleAt))
            locked = true
            guard deliveryEnabled else { return Scheduled(activateError: nil) }
            do {
                let _: Campaign = try await api.post("api/campaigns/\(result.id)/activate", json: VersionBody(version: result.version))
                return Scheduled(activateError: nil)
            } catch let failure as ApiError {
                return Scheduled(activateError: failure)
            }
        } catch let failure as ApiError {
            submitError = failure
        } catch {}
        return nil
    }

    /// Dismissing: a pending save is not lost.
    func finish() async {
        saveTask?.cancel()
        countTask?.cancel()
        if !locked, form != savedForm, form.isValid { await performSave() }
    }
}
