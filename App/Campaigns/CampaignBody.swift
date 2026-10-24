import Foundation

/// The body of `POST /api/campaigns` (with `id`) and `PUT /api/campaigns/:id` (with `version`): the fields the website sends,
/// with an explicit `null` where it sends one.
struct CampaignBody: Encodable {
    let id: String?
    let version: Int?
    let name: String
    let title: String
    let body: String
    let locale: String
    let audience: String
    let inactiveDays: Int
    let tierIds: [String]
    let customerCode: String?
    let branchId: String?
    let birthdayFrom: String?
    let birthdayTo: String?
    let coupon: CampaignCoupon?
    let translation: CampaignTranslation?

    private enum Keys: String, CodingKey {
        case id, version, name, title, body, locale, audience, inactiveDays, tierIds, customerCode, branchId
        case birthdayFrom, birthdayTo, coupon, translation
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encode(name, forKey: .name)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encode(locale, forKey: .locale)
        try container.encode(audience, forKey: .audience)
        try container.encode(inactiveDays, forKey: .inactiveDays)
        try container.encode(tierIds, forKey: .tierIds)
        try container.encode(customerCode, forKey: .customerCode)
        try container.encode(branchId, forKey: .branchId)
        try container.encode(birthdayFrom, forKey: .birthdayFrom)
        try container.encode(birthdayTo, forKey: .birthdayTo)
        try container.encode(coupon, forKey: .coupon)
        try container.encode(translation, forKey: .translation)
    }
}
