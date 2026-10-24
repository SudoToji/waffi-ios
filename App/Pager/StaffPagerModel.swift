import Foundation
import Observation

/// The staff Pager screen: whether the Business has the Pager, which Branch this person serves at, and that Branch's open tickets
/// (what `apps/web/src/features/pager/pages/PagerPage.tsx` does).
@Observable @MainActor
final class StaffPagerModel {
    enum Phase: Equatable {
        case loading
        case failed
        /// The Business's Plan or switch has no Pager.
        case off
        case noBranch
        /// `gone`: the Branch served at before is no longer usable.
        case choosing(gone: Bool)
        case board
    }

    /// Answers that mean the chosen Branch no longer works for this person.
    private static let branchRefusals: Set<String> = ["BRANCH_UNAVAILABLE", "BRANCH_NOT_ASSIGNED", "BRANCH_LOCKED"]

    let api: ApiClient
    private let storageKey: String

    private(set) var phase = Phase.loading
    /// The Branches this person may serve at: the working ones the API lists for them.
    private(set) var branches: [StaffBranch] = []
    private(set) var branch: StaffBranch?
    private(set) var tickets: [StaffTicket] = []
    private(set) var ticketsLoaded = false
    private(set) var loadError: ApiError?
    private(set) var listError: ApiError?
    private(set) var actionError: ApiError?
    /// The number of the last attempt, for the "already waiting" message.
    private(set) var attempt = ""
    private(set) var busy = false
    /// The ticket whose QR fills the screen.
    var shown: StaffTicket?

    init(api: ApiClient, userId: String) {
        self.api = api
        storageKey = "pager.branch.\(userId)"
    }

    private var remembered: String? { UserDefaults.standard.string(forKey: storageKey) }

    func load() async {
        loadError = nil
        do {
            let features: [String: Bool] = try await api.get("api/addons")
            guard features["pager"] == true else {
                phase = .off
                return
            }
            let all: [StaffBranch] = try await api.get("api/branches")
            branches = all.filter { $0.status == "working" }
            pick()
        } catch let error as ApiError {
            loadError = error
            phase = .failed
        } catch {}
    }

    func choose(_ branch: StaffBranch) {
        UserDefaults.standard.set(branch.id, forKey: storageKey)
        select(branch)
    }

    func changeBranch() {
        phase = .choosing(gone: false)
    }

    /// Reads the open tickets again; the screen calls it every 5 seconds.
    func refresh() async {
        guard phase == .board, let branch else { return }
        do {
            tickets = try await api.get("api/pager/tickets", query: [URLQueryItem(name: "branchId", value: branch.id)])
            ticketsLoaded = true
            listError = nil
        } catch let error as ApiError {
            await fail(error, list: true)
        } catch {}
    }

    /// True when the ticket was made, so the pad can clear.
    func create(number: String) async -> Bool {
        guard let branch else { return false }
        attempt = number
        return await act {
            let ticket: StaffTicket = try await self.api.post("api/pager/tickets", json: ["branchId": branch.id, "number": number])
            self.shown = ticket
        }
    }

    func ready(_ ticket: StaffTicket) async {
        _ = await act { let _: StaffTicket = try await self.api.post("api/pager/tickets/\(ticket.id)/ready") }
    }

    func done(_ ticket: StaffTicket) async {
        _ = await act { let _: StaffTicket = try await self.api.post("api/pager/tickets/\(ticket.id)/done") }
    }

    private func act(_ run: () async throws -> Void) async -> Bool {
        guard !busy else { return false }
        busy = true
        actionError = nil
        defer { busy = false }
        var done = false
        do {
            try await run()
            done = true
        } catch let error as ApiError {
            await fail(error, list: false)
        } catch {}
        await refresh()
        return done
    }

    private func fail(_ error: ApiError, list: Bool) async {
        if Self.branchRefusals.contains(error.code) {
            UserDefaults.standard.removeObject(forKey: storageKey)
            branch = nil
            await load()
            if case .choosing = phase { phase = .choosing(gone: true) }
        } else if list {
            listError = error
        } else {
            actionError = error
        }
    }

    /// The only working Branch, the remembered one, or a choice.
    private func pick() {
        if branches.isEmpty {
            branch = nil
            phase = .noBranch
        } else if branches.count == 1 {
            select(branches[0])
        } else if let kept = branches.first(where: { $0.id == remembered }) {
            select(kept)
        } else {
            branch = nil
            phase = .choosing(gone: remembered != nil)
        }
    }

    private func select(_ chosen: StaffBranch) {
        if branch?.id != chosen.id {
            branch = chosen
            tickets = []
            ticketsLoaded = false
        }
        phase = .board
    }
}
