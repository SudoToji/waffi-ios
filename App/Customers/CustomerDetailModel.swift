import Foundation
import Observation

/// One Customer's page: their figures, Cards and latest Transactions, and what the role may do to them
/// (`CustomerDrawer.tsx`, `CustomerActions.tsx` and `CustomerTierControls.tsx` on the website).
@Observable @MainActor
final class CustomerDetailModel {
    private let api: ApiClient
    /// Owner or Manager: edit, Card link, cut off the Apple pass, delete.
    let canManage: Bool
    /// Owner, Manager, or a Staff Member with `customers.set_tier`.
    let canSetTier: Bool
    /// May look a Card up (the Card Tier is read that way).
    let canLookup: Bool
    let tiersOn: Bool
    private let businessName: String

    private(set) var customer: Customer
    private(set) var figures: CustomerFigures?
    private(set) var figuresError: ApiError?
    /// 3, 6 or 12: the months of the gifts graph.
    var period = 6
    private(set) var tiers: [CustomerTier] = []
    /// A Card's id to the name of the Card Tier it is on (a `tier` Card).
    private(set) var cardTiers: [String: String] = [:]

    private(set) var busy = false
    var actionError: ApiError?
    /// The Card link just made. Shown once; closing it forgets it.
    private(set) var link: URL?
    private(set) var cutOffDone = false

    init(customer: Customer, api: ApiClient, account: AppAccount, tiersOn: Bool) {
        self.customer = customer
        self.api = api
        self.tiersOn = tiersOn
        businessName = account.business.name
        let user = account.user
        canManage = user.role == "owner" || user.role == "manager"
        canSetTier = user.may("customers.set_tier")
        canLookup = user.may("cards.view") || user.may("loyalty.earn") || user.may("loyalty.redeem")
    }

    // MARK: Reading

    func load() async {
        async let tierList: Void = loadTiers()
        await reloadCustomer()
        await tierList
        await loadCardTiers()
    }

    func reloadCustomer() async {
        let fresh: Customer? = try? await api.get("api/customers/\(customer.id)")
        if let fresh { customer = fresh }
    }

    func loadFigures() async {
        figuresError = nil
        do {
            let fresh: CustomerFigures = try await api.get(
                "api/customers/\(customer.id)/figures", query: [URLQueryItem(name: "months", value: String(period))])
            figures = fresh
        } catch let failure as ApiError {
            figuresError = failure
        } catch {}
    }

    private func loadTiers() async {
        guard tiersOn, canSetTier else { return }
        let list: [CustomerTier]? = try? await api.get("api/customer-tiers")
        if let list { tiers = list }
    }

    /// A Card Tier is on the Card itself, which the counter lookup reads: best effort, for the Cards that have one.
    private func loadCardTiers() async {
        guard canLookup else { return }
        for card in customer.activeCards where card.cardType == "tier" && cardTiers[card.id] == nil {
            let found: StaffCard? = try? await api.get(
                "api/loyalty/lookup", query: [URLQueryItem(name: "code", value: card.manualCode)])
            if let found, !found.tierName.isEmpty { cardTiers[card.id] = found.tierName }
        }
    }

    // MARK: Actions

    /// Edit: sends all five fields, as the website's form does.
    func save(_ form: CustomerForm) async -> Bool {
        await perform {
            let _: Customer = try await self.api.put("api/customers/\(self.customer.id)", json: CustomerUpdateBody(form))
            await self.reloadCustomer()
        }
    }

    func delete() async -> Bool {
        await perform {
            let _: IdAnswer = try await self.api.delete("api/customers/\(self.customer.id)")
        }
    }

    /// Issues the first Card or replaces the link to it; the answer is the only time the link is known.
    func issueLink() async -> Bool {
        await perform {
            let issued: CardLinkAnswer = try await self.api.post("api/enrollment/customers/\(self.customer.id)/card-link")
            var parts = URLComponents(url: ServerOrigin.current, resolvingAgainstBaseURL: false)
            parts?.path = "/\(self.customer.preferredLocale)/join/\(issued.slug)"
            parts?.fragment = "card=\(issued.token)"
            self.link = parts?.url
            await self.reloadCustomer()
        }
    }

    func closeLink() {
        link = nil
    }

    /// The Apple pass of the Customer's first Card, as the website cuts it off.
    func cutOffPass() async -> Bool {
        guard let card = customer.cards.first else { return false }
        let done = await perform {
            let _: CardCutOffAnswer = try await self.api.post("api/wallet/apple/cards/\(card.id)/pass/cut-off")
        }
        cutOffDone = done
        return done
    }

    func assignTier(_ tier: CustomerTier?, tellCustomer: Bool?) async -> Bool {
        let done = await perform {
            let _: IdAnswer = try await self.api.put(
                "api/customer-tiers/customers/\(self.customer.id)",
                json: TierAssignBody(tierId: tier?.id, tellCustomer: tellCustomer))
            await self.reloadCustomer()
            await self.loadFigures()
        }
        return done
    }

    func dismissQuiet() async {
        _ = await perform {
            let _: IdAnswer = try await self.api.post("api/customer-tiers/customers/\(self.customer.id)/dismiss-quiet")
            await self.reloadCustomer()
            await self.loadFigures()
        }
    }

    /// The WhatsApp message with the link, in the Customer's language.
    func whatsAppURL(link: URL) -> URL? {
        guard let phone = customer.phone, !phone.isEmpty else { return nil }
        let message = CustomerFormat.localized(
            "%@ loyalty card is now on Waffi. Tap to add it to your wallet: %@", language: customer.preferredLocale,
            businessName, link.absoluteString)
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = "wa.me"
        parts.path = "/" + phone.replacingOccurrences(of: "+", with: "")
        parts.queryItems = [URLQueryItem(name: "text", value: message)]
        return parts.url
    }

    private func perform(_ body: () async throws -> Void) async -> Bool {
        guard !busy else { return false }
        busy = true
        actionError = nil
        defer { busy = false }
        do {
            try await body()
            return true
        } catch let failure as ApiError {
            actionError = failure
        } catch {}
        return false
    }
}
