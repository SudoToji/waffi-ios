import Foundation
import Observation

/// The Overview's data: the dashboard numbers, the recent Transactions and the Branches to pick from
/// (what `apps/web/src/features/dashboard/pages/OverviewPage.tsx` reads).
@Observable @MainActor
final class OverviewModel {
    private let api: ApiClient

    private(set) var analytics: BusinessAnalytics?
    /// Nil until read; empty when there is nothing yet.
    private(set) var activity: [ActivityRow]?
    private(set) var activityFailed = false
    /// The numbers could not be read: with `analytics` nil this is the whole screen's error, otherwise the old numbers stay and a line says so.
    private(set) var error: ApiError?
    /// Every Branch, open or closed. The picker shows only when there is more than one, like the website's chips.
    private(set) var branches: [StaffBranch] = []

    init(api: ApiClient) {
        self.api = api
    }

    /// Reads everything for one Branch (nil = All Branches). `reset` drops what is shown first: another Branch's numbers must never stand in for this one's.
    func load(branch: String?, reset: Bool) async {
        if reset {
            analytics = nil
            activity = nil
        }
        error = nil
        async let all = branchList()
        async let recent = recentActivity(branch: branch)
        async let numbers = loadAnalytics(branch: branch)
        let (list, rows, result) = await (all, recent, numbers)
        if Task.isCancelled { return }
        if let list { branches = list }
        switch result {
        case .success(let value): analytics = value
        case .failure(let failure): error = failure
        }
        activityFailed = rows == nil
        if let rows { activity = rows }
    }

    private func branchList() async -> [StaffBranch]? {
        try? await api.get("api/branches")
    }

    private func loadAnalytics(branch: String?) async -> Result<BusinessAnalytics, ApiError> {
        do {
            return .success(try await api.get("api/businesses/current/analytics", query: Self.query(branch: branch)))
        } catch let error as ApiError {
            return .failure(error)
        } catch {
            return .failure(.network)
        }
    }

    /// The newest Transactions of the last 7 days; nil when they could not be read.
    private func recentActivity(branch: String?) async -> [ActivityRow]? {
        let query = [URLQueryItem(name: "period", value: "7d")] + Self.query(branch: branch)
        let page: ActivityPage? = try? await api.get("api/transactions", query: query)
        return page.map { Array($0.items.prefix(5)) }
    }

    private static func query(branch: String?) -> [URLQueryItem] {
        branch.map { [URLQueryItem(name: "branch", value: $0)] } ?? []
    }
}
