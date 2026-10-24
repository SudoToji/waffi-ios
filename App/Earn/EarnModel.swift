import Foundation
import Observation

/// The Earn & redeem tab: which Branch this person serves at, finding a Customer's Card, and the Operations on it
/// (what `apps/web/src/features/loyalty/pages/LoyaltyPage.tsx` and its `useLoyalty` hook do).
@Observable @MainActor
final class EarnModel {
    enum Phase: Equatable {
        case loading
        case failed
        /// `gone`: the Branch served at before is no longer usable.
        case choosing(gone: Bool)
        /// Looking a Card up works with or without a Branch; Earn and Redeem wait for one.
        case ready
    }

    /// Answers that mean the chosen Branch no longer works for this person.
    private static let branchRefusals: Set<String> = ["BRANCH_UNAVAILABLE", "BRANCH_NOT_ASSIGNED", "BRANCH_LOCKED"]
    /// An answer that leaves the outcome unknown: the Operation may have been recorded.
    private static let unknownOutcome: Set<String> = ["NETWORK", "GENERIC", "INVALID_RESPONSE", ""]
    /// Refusals given before the server looks up the `operationId`; after an unknown outcome they prove nothing, so the id is kept.
    private static let beforeReplay: Set<String> = [
        "RATE_LIMIT", "UNAUTHENTICATED", "TEAM_SEAT_LOCKED", "FORBIDDEN", "PASSWORD_CHANGE_REQUIRED", "MFA_REQUIRED",
        "INVALID_ORIGIN", "SUBSCRIPTION_ENDED", "AWAITING_APPROVAL", "DATABASE_UNAVAILABLE", "OPERATION_STORAGE",
    ]
    private static let lookupPattern =
        "^(?!000000$)(?:[0-9]{6}|\\+[1-9][0-9]{6,14}|waffi:card:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$"
    private static let pageSize = 12

    let api: ApiClient
    let canEarn: Bool
    let canRedeem: Bool
    private let branchKey: String
    private let operationKey: String

    private(set) var phase = Phase.loading
    private(set) var loadError: ApiError?
    /// The Branches this person may serve at: the working ones the API lists for them.
    private(set) var branches: [StaffBranch] = []
    private(set) var branch: StaffBranch?

    // Finding the Customer
    private(set) var card: StaffCard?
    private(set) var searching = false
    /// The text typed or scanned is not a Manual Code, a phone number or a Waffi Card QR.
    private(set) var codeInvalid = false
    private(set) var lookupError: ApiError?
    private(set) var results: [DirectoryCustomer] = []
    private(set) var nextCursor: String?
    private(set) var resultsLoading = false
    private(set) var resultsError: ApiError?
    private(set) var recent: [RecentServe] = []

    // Operations
    var draft: OperationDraft?
    private(set) var unresolved: PendingOperation?
    /// An attempt at the unresolved Operation ended with an unknown outcome (it may have been recorded).
    private var uncertain = false
    private(set) var busy = false
    private(set) var operationError: ApiError?
    private(set) var receipt: OperationReceipt?
    /// Bumped on every success and failure, for the haptics.
    private(set) var successCount = 0
    private(set) var failureCount = 0

    init(api: ApiClient, account: AppAccount) {
        self.api = api
        canEarn = account.user.may("loyalty.earn")
        canRedeem = account.user.may("loyalty.redeem")
        branchKey = "counter.branch.\(account.business.id).\(account.user.id)"
        operationKey = "counter.operation.\(account.business.id).\(account.user.id)"
        if let data = UserDefaults.standard.data(forKey: operationKey),
           let stored = try? JSONDecoder().decode(PendingOperation.self, from: data) {
            unresolved = stored
            uncertain = true
        }
    }

    var busyOrPending: Bool { busy || searching || draft != nil }

    /// The last attempt ended for good: the Operation was refused, so it can be dropped. After an unknown outcome the refusal proves nothing.
    var definitiveFailure: Bool {
        guard unresolved != nil, let code = operationError?.code else { return false }
        return !Self.unknownOutcome.contains(code) && !(uncertain && Self.beforeReplay.contains(code))
    }

    // MARK: Branch

    func load() async {
        loadError = nil
        do {
            let all: [StaffBranch] = try await api.get("api/branches")
            branches = all.filter { $0.status == "working" }
            pick()
        } catch let error as ApiError {
            loadError = error
            phase = .failed
        } catch {}
    }

    func choose(_ chosen: StaffBranch) {
        UserDefaults.standard.set(chosen.id, forKey: branchKey)
        branch = chosen
        phase = .ready
    }

    func changeBranch() {
        guard !busyOrPending else { return }
        phase = .choosing(gone: false)
    }

    /// The only working Branch, the remembered one, or a choice.
    private func pick() {
        let remembered = UserDefaults.standard.string(forKey: branchKey)
        if branches.count == 1 {
            branch = branches[0]
            phase = .ready
        } else if let kept = branches.first(where: { $0.id == remembered }) {
            branch = kept
            phase = .ready
        } else if branches.isEmpty {
            branch = nil
            phase = .ready
        } else {
            branch = nil
            phase = .choosing(gone: remembered != nil)
        }
    }

    private func branchRefused() async {
        UserDefaults.standard.removeObject(forKey: branchKey)
        branch = nil
        await load()
        if case .choosing = phase { phase = .choosing(gone: true) }
    }

    // MARK: Finding the Customer

    /// Reads a Card by what its QR holds (a Manual Code or the older `waffi:card:` text) or by a phone number.
    @discardableResult
    func lookup(_ raw: String) async -> Bool {
        guard unresolved == nil, !busy, !searching, draft == nil else { return false }
        receipt = nil
        operationError = nil
        lookupError = nil
        guard let code = Self.normalized(raw) else {
            codeInvalid = true
            return false
        }
        codeInvalid = false
        searching = true
        defer { searching = false }
        do {
            let found: StaffCard = try await api.get("api/loyalty/lookup", query: [URLQueryItem(name: "code", value: code)])
            card = found
            return true
        } catch let error as ApiError {
            lookupError = error
            failureCount += 1
        } catch {}
        return false
    }

    /// The text in the form `GET /api/loyalty/lookup` accepts, or nil. The website's `normalizeLookupCode` and the API's check.
    static func normalized(_ raw: String) -> String? {
        var text = ""
        for scalar in raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().unicodeScalars {
            switch scalar.value {
            case 0x0660...0x0669: text.unicodeScalars.append(UnicodeScalar(scalar.value - 0x0660 + 0x30)!)
            case 0x06F0...0x06F9: text.unicodeScalars.append(UnicodeScalar(scalar.value - 0x06F0 + 0x30)!)
            default: text.unicodeScalars.append(scalar)
            }
        }
        if !text.hasPrefix("waffi:card:") {
            text = text.filter { !" -()".contains($0) }
            // An Egyptian mobile number written locally (01001234567) is +201001234567.
            if text.count == 11, text.hasPrefix("0"), text.allSatisfy(\.isNumber) { text = "+20" + text.dropFirst() }
        }
        return text.range(of: lookupPattern, options: .regularExpression) == nil ? nil : text
    }

    /// Searches the Customer directory as the website's picker does (name, phone, email or Manual Code), 12 at a time.
    func search(_ text: String) async {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            results = []
            nextCursor = nil
            resultsError = nil
            return
        }
        await loadResults(query: query, cursor: nil)
    }

    func loadMore(_ text: String) async {
        guard let nextCursor, !resultsLoading else { return }
        await loadResults(query: text.trimmingCharacters(in: .whitespacesAndNewlines), cursor: nextCursor)
    }

    private func loadResults(query: String, cursor: String?) async {
        resultsLoading = true
        resultsError = nil
        defer { resultsLoading = false }
        var items = [
            URLQueryItem(name: "search", value: query), URLQueryItem(name: "sort", value: "visits"),
            URLQueryItem(name: "limit", value: String(Self.pageSize)),
        ]
        if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
        do {
            let page: DirectoryPage = try await api.get("api/customer-tiers/directory", query: items)
            results = cursor == nil ? page.items : results + page.items
            nextCursor = page.nextCursor
        } catch let error as ApiError {
            resultsError = error
        } catch {}
    }

    /// Back to finding a Customer ("Next customer").
    func clearCustomer() {
        guard !busy, !searching, draft == nil else { return }
        card = nil
        receipt = nil
        operationError = nil
        lookupError = nil
        codeInvalid = false
    }

    /// Reads the Card again, so it shows what the server now holds.
    func refreshCard(code known: String? = nil) async {
        guard let code = known ?? card?.manualCode, !searching else { return }
        searching = true
        defer { searching = false }
        do {
            let found: StaffCard = try await api.get("api/loyalty/lookup", query: [URLQueryItem(name: "code", value: code)])
            card = found
        } catch let error as ApiError {
            lookupError = error
        } catch {}
    }

    // MARK: Operations

    func prepareEarn(quantity: Int?, amountMinor: Int?) {
        guard canEarn, branch != nil, unresolved == nil, !busyOrPending else { return }
        receipt = nil
        draft = OperationDraft(type: "earn", reward: nil, quantity: quantity, amountMinor: amountMinor, needsAmount: false)
    }

    func prepareRedeem(_ reward: LoyaltyReward) {
        guard canRedeem, branch != nil, reward.eligible, unresolved == nil, !busyOrPending else { return }
        receipt = nil
        draft = OperationDraft(type: "redeem", reward: reward, quantity: nil, amountMinor: nil, needsAmount: reward.requiresPurchase)
    }

    func cancelDraft() {
        if !busy { draft = nil }
    }

    /// Confirm: the Operation gets its `operationId`, is kept on the phone, then sent. `entered` is the amount a Reward bought with a purchase asks for.
    func confirm(amountMinor entered: Int?) async {
        guard let draft, let card, let branch, !busy else { return }
        let amount = draft.amountMinor ?? entered
        if draft.needsAmount && amount == nil { return }
        let reward = draft.reward
        let pending = PendingOperation(
            cardId: card.id, code: card.manualCode, customerName: card.customerName, unit: card.unitLabel,
            rewardName: reward?.displayName ?? "",
            input: OperationInput(
                operationId: UUID().uuidString.lowercased(), branchId: branch.id, type: draft.type,
                grantId: reward?.grantId, rewardId: reward?.id, rewardVersion: reward?.version,
                amountMinor: amount, quantity: draft.quantity,
                expectedBalance: draft.type == "redeem" && reward?.grantId == nil ? Int(card.balance) : nil))
        self.draft = nil
        await run(pending)
    }

    /// "Retry same operation": the stored Operation again, with the same `operationId`.
    func retry() async {
        if let unresolved { await run(unresolved) }
    }

    /// "Return to card lookup": drops an Operation the server refused for good.
    func dismissFailure() {
        guard definitiveFailure, !busy else { return }
        forgetOperation()
        card = nil
        operationError = nil
    }

    private func run(_ pending: PendingOperation) async {
        guard !busy else { return }
        if unresolved != nil, let code = operationError?.code, Self.unknownOutcome.contains(code) { uncertain = true }
        unresolved = pending
        if let data = try? JSONEncoder().encode(pending) { UserDefaults.standard.set(data, forKey: operationKey) }
        busy = true
        operationError = nil
        receipt = nil
        defer { busy = false }
        do {
            let result: LoyaltyResult = try await api.post("api/loyalty/\(pending.cardId)/operations", json: pending.input)
            forgetOperation()
            receipt = OperationReceipt(
                type: result.type, amount: result.amount, balance: result.balance, unit: pending.unit,
                rewardName: result.displayRewardName)
            successCount += 1
            remember(pending, result)
            await refreshCard(code: pending.code)
        } catch let error as ApiError {
            operationError = error
            failureCount += 1
            if Self.branchRefusals.contains(error.code) { await branchRefused() }
        } catch {}
    }

    private func forgetOperation() {
        UserDefaults.standard.removeObject(forKey: operationKey)
        unresolved = nil
        uncertain = false
    }

    private func remember(_ pending: PendingOperation, _ result: LoyaltyResult) {
        let summary: String
        if result.type == "redeem" {
            let name = result.displayRewardName
            summary = name.isEmpty ? String(localized: "Redeemed") : String(localized: "Redeemed \(name)")
        } else {
            let amount = result.amount.formatted(.number)
            summary = String(localized: "Earned \(amount) \(pending.unit)")
        }
        recent.insert(RecentServe(customerName: pending.customerName, summary: summary, date: .now), at: 0)
        if recent.count > 5 { recent.removeLast(recent.count - 5) }
    }
}
