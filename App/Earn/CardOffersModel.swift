import Foundation
import Observation

/// "Other offers" on a Card: the campaign coupons and the Birthday offer a Staff Member can honour at the counter. They are
/// separate from loyalty Rewards and do not touch the Balance (`BirthdayOffers` and `CustomerCoupons` on the website's counter page).
@Observable @MainActor
final class CardOffersModel {
    /// Refusals after which the same Operation can never succeed, so its retry key is dropped.
    private static let definite: Set<String> = [
        "COUPON_UNAVAILABLE", "BIRTHDAY_OFFER_UNAVAILABLE", "CARD_NOT_FOUND", "OPERATION_CONFLICT", "FORBIDDEN",
    ]
    private static let branchRefusals: Set<String> = ["BRANCH_UNAVAILABLE", "BRANCH_NOT_ASSIGNED", "BRANCH_LOCKED"]

    private let api: ApiClient
    private let cardId: String

    private(set) var coupons: [IssuedCoupon] = []
    private(set) var birthdays: [BirthdayOffer] = []
    private(set) var loading = true
    private(set) var loadError: ApiError?
    /// The offer the Staff Member asked to redeem, awaiting the confirmation.
    var selected: CounterOffer?
    private(set) var redeeming = false
    private(set) var error: ApiError?
    /// What was redeemed last: shown until the next attempt.
    private(set) var redeemed: CounterOffer?
    /// The retry key of the offer being redeemed: the same one again after a failure that proves nothing.
    @ObservationIgnored private var attempt: (offer: String, operationId: String)?

    init(api: ApiClient, cardId: String) {
        self.api = api
        self.cardId = cardId
    }

    var isEmpty: Bool { coupons.isEmpty && birthdays.isEmpty }

    func load() async {
        loadError = nil
        do {
            async let couponList: [IssuedCoupon] = api.get("api/loyalty/\(cardId)/coupons")
            async let birthdayList: [BirthdayOffer] = api.get("api/loyalty/\(cardId)/birthday-offers")
            (coupons, birthdays) = try await (couponList, birthdayList)
        } catch let failure as ApiError {
            loadError = failure
        } catch {}
        loading = false
    }

    /// Redeems an offer at `branchId`. True when it was recorded; `branchRefused` hears an answer that says the Branch no longer works.
    func redeem(_ offer: CounterOffer, branchId: String, branchRefused: () async -> Void) async -> Bool {
        guard !redeeming else { return false }
        selected = nil
        redeeming = true
        error = nil
        redeemed = nil
        defer { redeeming = false }
        let operationId: String
        if let attempt, attempt.offer == offer.id {
            operationId = attempt.operationId
        } else {
            operationId = UUID().uuidString.lowercased()
            attempt = (offer.id, operationId)
        }
        let path: String
        switch offer {
        case .coupon(let coupon): path = "api/loyalty/\(cardId)/coupons/\(coupon.id)/redeem"
        case .birthday(let birthday): path = "api/loyalty/\(cardId)/birthday-offers/\(birthday.id)/redeem"
        }
        do {
            let _: RedeemedOffer = try await api.post(path, json: OfferRedeemBody(operationId: operationId, branchId: branchId))
            attempt = nil
            redeemed = offer
            await load()
            return true
        } catch let failure as ApiError {
            error = failure
            if Self.definite.contains(failure.code) || Self.branchRefusals.contains(failure.code) { attempt = nil }
            if Self.branchRefusals.contains(failure.code) { await branchRefused() }
            if failure.code == "COUPON_UNAVAILABLE" || failure.code == "BIRTHDAY_OFFER_UNAVAILABLE" { await load() }
        } catch {}
        return false
    }
}

/// What the redeem routes answer with; the app only needs to know it worked.
struct RedeemedOffer: Decodable {
    let id: String
}
