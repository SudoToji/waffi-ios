import Foundation

/// The same message in the other language (`CampaignTranslation` in waffi `packages/shared`).
struct CampaignTranslation: Codable, Equatable {
    var title: String
    var body: String
}

/// A coupon on a message: its text, and either hours after processing starts or a fixed expiry (`CampaignCouponInput`).
struct CampaignCoupon: Codable, Equatable {
    var description: String
    var validHours: Int
    var expiresAt: Date?

    init(description: String, validHours: Int, expiresAt: Date? = nil) {
        self.description = description
        self.validHours = validHours
        self.expiresAt = expiresAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        description = try container.decode(String.self, forKey: .description)
        validHours = try container.decode(Int.self, forKey: .validHours)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
    }

    /// The website sends `expiresAt: null` for a coupon that runs for hours.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(description, forKey: .description)
        try container.encode(validHours, forKey: .validHours)
        if let expiresAt {
            try container.encode(expiresAt.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true)), forKey: .expiresAt)
        } else {
            try container.encodeNil(forKey: .expiresAt)
        }
    }

    private enum Keys: String, CodingKey { case description, validHours, expiresAt }
}

/// A campaign as the API answers it (`CampaignDraft`): `draft`, `scheduled`, `processing` or `completed`.
struct Campaign: Decodable, Identifiable, Equatable {
    let id: String
    let status: String
    let version: Int
    /// A scheduled campaign that is not armed yet, or one that was stopped.
    let deliveryPaused: Bool
    let scheduledAt: Date?
    let scheduleTimezone: String?
    let name: String
    let title: String
    let body: String
    let locale: String
    let translation: CampaignTranslation?
    let audience: String
    let inactiveDays: Int
    let tierIds: [String]?
    let customerCode: String?
    let branchId: String?
    let birthdayFrom: String?
    let birthdayTo: String?
    let coupon: CampaignCoupon?
    let createdAt: Date

    /// When it was sent (a send now arms the campaign for that moment) or, failing that, made.
    var sentAt: Date { scheduledAt ?? createdAt }
}

struct CampaignPage: Decodable {
    let items: [Campaign]
    let total: Int
    let page: Int
    let pageSize: Int
}

/// `GET /api/campaigns/audience`: `optedIn` is who gets the message, `walletPasses` who of them has a pass in a wallet.
struct CampaignCounts: Decodable, Equatable {
    let matched: Int
    let optedIn: Int
    let walletPasses: Int
}

/// What the delivery report holds that a card needs: the number of deliveries in each status.
struct DeliveryReport: Decodable {
    let campaign: Campaign
    let counts: [String: Int]
}

/// `GET /api/platform/features`: sending needs one channel switched on.
struct PlatformFeatures: Decodable, Equatable {
    let googleWallet: Bool
    let appleLivePasses: Bool

    var deliveryEnabled: Bool { googleWallet || appleLivePasses }
}

struct OkReply: Decodable {
    let ok: Bool
}

struct VersionBody: Encodable {
    let version: Int
}

struct ScheduleBody: Encodable {
    let version: Int
    let scheduledAt: String
    let timezone: String

    init(version: Int, at date: Date) {
        self.version = version
        scheduledAt = date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
        timezone = TimeZone.current.identifier
    }
}
