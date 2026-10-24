import Foundation

/// A campaign coupon the Card holds (`IssuedCampaignCoupon`): `GET /api/loyalty/:cardId/coupons` lists the redeemable ones.
struct IssuedCoupon: Decodable, Identifiable, Equatable {
    let id: String
    let description: String
    let expiresAt: Date
}

/// A Birthday offer of the Card's Customer (`BirthdayOffer`): `GET /api/loyalty/:cardId/birthday-offers`.
struct BirthdayOffer: Decodable, Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let description: String
    /// The language the offer was written in.
    let locale: String
    let expiresAt: Date
}

/// The body of both redeem routes (`CounterRedeemInput`): the retry key and the Branch, as for Operations.
struct OfferRedeemBody: Encodable {
    let operationId: String
    let branchId: String
}

/// Either kind of offer the counter can redeem.
enum CounterOffer: Identifiable, Equatable {
    case coupon(IssuedCoupon)
    case birthday(BirthdayOffer)

    var id: String {
        switch self {
        case .coupon(let coupon): "coupon-" + coupon.id
        case .birthday(let offer): "birthday-" + offer.id
        }
    }

    var description: String {
        switch self {
        case .coupon(let coupon): coupon.description
        case .birthday(let offer): offer.description
        }
    }
}
