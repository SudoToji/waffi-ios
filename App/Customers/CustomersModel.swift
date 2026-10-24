import Foundation
import Observation

/// The Customers list: search, the tier filter, sort and Joining Branch chips, paged by cursor
/// (what `apps/web/src/features/customers/hooks/useCustomers.ts` and `CustomersPage.tsx` do).
@Observable @MainActor
final class CustomersModel {
    private static let pageSize = 25

    private let api: ApiClient
    /// The Business has the Customer Tiers Feature on.
    let tiersOn: Bool
    /// May set Customer Tiers: sees the Quiet members filter.
    let canSetTier: Bool

    var search = ""
    var tier = TierFilter.all
    var sort = CustomerSort.newest
    var joining = ""

    private(set) var customers: [Customer] = []
    private(set) var nextCursor: String?
    /// A page for the current query is being read.
    private(set) var loading = true
    private(set) var loadingMore = false
    private(set) var error: ApiError?
    private(set) var moreError: ApiError?
    private(set) var tiers: [CustomerTier] = []
    private(set) var counts: JoiningBranchCounts?
    /// The query the shown `customers` answer.
    private var loaded: CustomerQuery?
    private var generation = 0

    init(api: ApiClient, tiersOn: Bool, canSetTier: Bool) {
        self.api = api
        self.tiersOn = tiersOn
        self.canSetTier = canSetTier
    }

    var query: CustomerQuery {
        CustomerQuery(
            search: String(search.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100)),
            tier: tiersOn ? tier : .all,
            sort: !tiersOn && sort == .tier ? .newest : sort,
            joining: showJoining ? joining : "")
    }

    /// The sorts on offer: "Highest tier" needs Customer Tiers.
    var sorts: [CustomerSort] { CustomerSort.allCases.filter { tiersOn || $0 != .tier } }

    /// Chips and a Joining Branch show only for a Business with more than one Branch.
    var showJoining: Bool { (counts?.branchCount ?? 0) > 1 }

    var filtered: Bool { !query.search.isEmpty || query.tier != .all || !query.joining.isEmpty }

    // MARK: Reading

    /// The tiers and the Joining Branch counts: what the chips are made of.
    func loadSide() async {
        if tiersOn {
            let list: [CustomerTier]? = try? await api.get("api/customer-tiers")
            if let list { tiers = list }
        }
        let fresh: JoiningBranchCounts? = try? await api.get("api/customers/joining-branches")
        if let fresh { counts = fresh }
    }

    /// Reads the first page of the current query. A newer call makes an older one's answer be dropped.
    func reload() async {
        generation += 1
        let mine = generation
        let asked = query
        loading = true
        error = nil
        moreError = nil
        defer { if mine == generation { loading = false } }
        do {
            let page: CustomerPage = try await api.get("api/customers", query: items(asked, cursor: nil))
            guard mine == generation else { return }
            customers = page.items
            nextCursor = page.nextCursor
            loaded = asked
        } catch let failure as ApiError {
            guard mine == generation else { return }
            if loaded != asked {
                customers = []
                nextCursor = nil
            }
            error = failure
        } catch {}
    }

    /// Pull to refresh: the list, the tiers and the counts.
    func refresh() async {
        async let side: Void = loadSide()
        await reload()
        await side
    }

    func loadMore() async {
        guard let cursor = nextCursor, !loading, !loadingMore, let asked = loaded else { return }
        loadingMore = true
        moreError = nil
        defer { loadingMore = false }
        do {
            let page: CustomerPage = try await api.get("api/customers", query: items(asked, cursor: cursor))
            guard asked == loaded, cursor == nextCursor else { return }
            let seen = Set(customers.map(\.id))
            customers += page.items.filter { !seen.contains($0.id) }
            nextCursor = page.nextCursor
        } catch let failure as ApiError {
            moreError = failure
        } catch {}
    }

    func customer(id: String) -> Customer? { customers.first { $0.id == id } }

    /// The search the shown list answers.
    var loadedSearch: String { loaded?.search ?? "" }

    /// Adds a Customer (Owner or Manager); the API's refusal, or nil when it was added.
    func create(_ form: CustomerForm) async -> ApiError? {
        do {
            let _: Customer = try await api.post("api/customers", json: CustomerCreateBody(form))
            await loadSide()
            return nil
        } catch let failure as ApiError {
            return failure
        } catch {
            return ApiError.network
        }
    }

    /// A Customer changed on its page: the row follows.
    func update(_ customer: Customer) {
        if let index = customers.firstIndex(where: { $0.id == customer.id }) { customers[index] = customer }
    }

    func remove(id: String) {
        customers.removeAll { $0.id == id }
    }

    private func items(_ asked: CustomerQuery, cursor: String?) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "sort", value: asked.sort.rawValue),
            URLQueryItem(name: "limit", value: String(Self.pageSize)),
        ]
        switch asked.tier {
        case .all: break
        case .loyalNoTier: items.append(URLQueryItem(name: "loyalNoTier", value: "true"))
        case .quiet: items.append(URLQueryItem(name: "quiet", value: "true"))
        case .tier(let id): items.append(URLQueryItem(name: "tierId", value: id))
        }
        if !asked.joining.isEmpty { items.append(URLQueryItem(name: "joiningBranch", value: asked.joining)) }
        if !asked.search.isEmpty { items.append(URLQueryItem(name: "search", value: asked.search)) }
        if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
        return items
    }
}
