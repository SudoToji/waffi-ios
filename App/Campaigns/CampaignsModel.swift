import Foundation
import Observation

/// The Messages tab: saved messages (drafts and what was sent, grouped), the scheduled ones, and the actions on them
/// (what `apps/web/src/features/campaigns/hooks/useCampaigns.ts` does with its Drafts, Scheduled and Sent views).
@Observable @MainActor
final class CampaignsModel {
    let api: ApiClient
    let tiersOn: Bool

    private(set) var drafts: [Campaign] = []
    private(set) var scheduled: [Campaign] = []
    private(set) var sent: [Campaign] = []
    private(set) var sentTotal = 0
    private var sentPage = 1
    /// The delivery report's count of each status, by campaign.
    private(set) var counts: [String: [String: Int]] = [:]
    private(set) var features: PlatformFeatures?
    private(set) var tiers: [CustomerTier] = []
    private(set) var branches: [StaffBranch] = []

    private(set) var loading = true
    private(set) var loadingMore = false
    private(set) var error: ApiError?
    private(set) var moreError: ApiError?
    /// A change (cancel, stop, delete, activate) is going on.
    private(set) var busy = false
    private(set) var actionError: ApiError?

    init(api: ApiClient, tiersOn: Bool) {
        self.api = api
        self.tiersOn = tiersOn
    }

    var messages: [SavedMessage] { SavedMessage.groups(sent) }
    var hasMoreSent: Bool { sent.count < sentTotal }
    var isEmpty: Bool { drafts.isEmpty && scheduled.isEmpty && sent.isEmpty }
    var deliveryEnabled: Bool { features?.deliveryEnabled ?? true }

    /// The delivered (`accepted`) count over every send of a message; nil until the reports are read.
    func delivered(_ message: SavedMessage) -> Int? {
        let known = message.sends.compactMap { counts[$0.id]?["accepted"] }
        return known.isEmpty ? nil : known.reduce(0, +)
    }

    /// The report counts over every send of a message, for the results sheet.
    func results(_ message: SavedMessage) -> [String: Int] {
        var total: [String: Int] = [:]
        for send in message.sends { for (status, number) in counts[send.id] ?? [:] { total[status, default: 0] += number } }
        return total
    }

    // MARK: Reading

    func load() async {
        error = nil
        async let draftPage = page("draft", 1)
        async let scheduledPage = page("scheduled", 1)
        async let sentPageResult = page("delivery", 1)
        async let side: Void = loadSide()
        do {
            let (draftsNow, scheduledNow, sentNow) = try await (draftPage, scheduledPage, sentPageResult)
            drafts = draftsNow.items
            scheduled = scheduledNow.items
            sent = sentNow.items
            sentTotal = sentNow.total
            sentPage = 1
        } catch let failure as ApiError {
            error = failure
        } catch {}
        await side
        loading = false
        await loadCounts()
    }

    /// The Feature switches of the platform, the tiers and the Branches the composer needs.
    private func loadSide() async {
        let platform: PlatformFeatures? = try? await api.get("api/platform/features")
        if let platform { features = platform }
        if tiersOn {
            let list: [CustomerTier]? = try? await api.get("api/customer-tiers")
            if let list { tiers = list }
        }
        let all: [StaffBranch]? = try? await api.get("api/branches")
        if let all { branches = all }
    }

    func loadMoreSent() async {
        guard hasMoreSent, !loadingMore else { return }
        loadingMore = true
        moreError = nil
        defer { loadingMore = false }
        do {
            let next = try await page("delivery", sentPage + 1)
            let seen = Set(sent.map(\.id))
            sent += next.items.filter { !seen.contains($0.id) }
            sentTotal = next.total
            sentPage += 1
            await loadCounts()
        } catch let failure as ApiError {
            moreError = failure
        } catch {}
    }

    private func page(_ status: String, _ number: Int) async throws -> CampaignPage {
        try await api.get(
            "api/campaigns",
            query: [URLQueryItem(name: "status", value: status), URLQueryItem(name: "page", value: String(number))])
    }

    /// Reads the delivery report of each campaign that has none yet, and again of those still being sent.
    private func loadCounts() async {
        let wanted = sent.filter { counts[$0.id] == nil || $0.status == "processing" }
        guard !wanted.isEmpty else { return }
        let api = api
        let fresh = await withTaskGroup(of: (String, [String: Int])?.self, returning: [(String, [String: Int])].self) { group in
            for campaign in wanted {
                group.addTask {
                    let report: DeliveryReport? = try? await api.get(
                        "api/campaigns/\(campaign.id)/deliveries", query: [URLQueryItem(name: "page", value: "1")])
                    return report.map { (campaign.id, $0.counts) }
                }
            }
            var answers: [(String, [String: Int])] = []
            for await answer in group { if let answer { answers.append(answer) } }
            return answers
        }
        for (id, numbers) in fresh { counts[id] = numbers }
    }

    // MARK: Actions

    func cancelSchedule(_ campaign: Campaign) async -> Bool {
        await change { let _: Campaign = try await self.api.post("api/campaigns/\(campaign.id)/cancel", json: VersionBody(version: campaign.version)) }
    }

    func activate(_ campaign: Campaign) async -> Bool {
        await change { let _: Campaign = try await self.api.post("api/campaigns/\(campaign.id)/activate", json: VersionBody(version: campaign.version)) }
    }

    func stop(_ campaign: Campaign) async -> Bool {
        await change { let _: Campaign = try await self.api.post("api/campaigns/\(campaign.id)/stop", json: VersionBody(version: campaign.version)) }
    }

    func deleteDraft(_ campaign: Campaign) async -> Bool {
        await change { let _: OkReply = try await self.api.delete("api/campaigns/\(campaign.id)", json: VersionBody(version: campaign.version)) }
    }

    func clearActionError() { actionError = nil }

    /// Runs a change; on `CAMPAIGN_CHANGED` the lists are read again (it moved on another device).
    private func change(_ work: () async throws -> Void) async -> Bool {
        guard !busy else { return false }
        busy = true
        actionError = nil
        defer { busy = false }
        do {
            try await work()
            await load()
            return true
        } catch let failure as ApiError {
            actionError = failure
            if failure.code == "CAMPAIGN_CHANGED" || failure.code == "CAMPAIGN_NOT_FOUND" { await load() }
        } catch {}
        return false
    }
}
