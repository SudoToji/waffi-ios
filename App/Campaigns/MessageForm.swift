import Foundation

/// What the Owner is writing: the website's composer fields (`useCampaigns` draft) in a form the screen edits.
/// `request(id:version:)` is what the API takes; `isValid` is `validCampaign` in waffi `packages/shared`.
struct MessageForm: Equatable {
    /// The audiences a new message can be aimed at, in the website's order (birthdays last).
    static let audiences = [
        "all", "inactive", "near_reward", "tiers", "customer", "joining_branch", "birthday_today", "birthday_month",
        "birthday_range",
    ]

    var locale = "en"
    var title = ""
    var body = ""
    var translating = false
    var translationTitle = ""
    var translationBody = ""
    var audience = "all"
    var inactiveDays = 30
    var tierIds: [String] = []
    var customerCode = ""
    var branchId = ""
    /// `MM-DD`, both for a birthday range.
    var birthdayFrom = ""
    var birthdayTo = ""
    var coupon = false
    var couponKind = CouponKind.custom
    var couponDetail = ""
    var couponText = ""
    var couponHours = 48
    var fixedExpiry = false
    var couponExpiresAt = Date.now.addingTimeInterval(48 * 3600)

    init(locale: String = "en") { self.locale = locale }

    /// A saved or sent message as a form. `fresh` (a copy to send again) drops a fixed coupon expiry that has passed.
    init(_ campaign: Campaign, fresh: Bool = false) {
        locale = campaign.locale
        title = campaign.title
        body = campaign.body
        if let translation = campaign.translation {
            translating = true
            translationTitle = translation.title
            translationBody = translation.body
        }
        audience = campaign.audience
        inactiveDays = campaign.inactiveDays
        tierIds = campaign.tierIds ?? []
        customerCode = campaign.customerCode ?? ""
        branchId = campaign.branchId ?? ""
        birthdayFrom = campaign.birthdayFrom ?? ""
        birthdayTo = campaign.birthdayTo ?? ""
        if let saved = campaign.coupon {
            coupon = true
            // The kind is not stored: an opened message shows its coupon as Custom.
            couponText = saved.description
            couponHours = saved.validHours
            if let expiry = saved.expiresAt, !fresh || expiry > Date.now.addingTimeInterval(120) {
                fixedExpiry = true
                couponExpiresAt = expiry
            }
        }
    }

    var otherLocale: String { locale == "ar" ? "en" : "ar" }

    var couponDescription: String {
        couponKind == .custom ? couponText : couponKind.text(detail: couponDetail, locale: locale)
    }

    /// The composer has no name field: a message is named after its title, with the date added when the title is too short.
    var name: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 3 { return trimmed }
        let day = Date.now.formatted(.iso8601.year().month().day())
        return (trimmed + " " + day).trimmingCharacters(in: .whitespaces)
    }

    /// The audience count needs the audience's own choice made.
    var audienceReady: Bool {
        switch audience {
        case "tiers": return !tierIds.isEmpty
        case "customer": return Self.validCode(customerCode)
        case "joining_branch": return !branchId.isEmpty
        case "birthday_range": return Self.monthDay(birthdayFrom) && Self.monthDay(birthdayTo)
        default: return true
        }
    }

    var isValid: Bool {
        func length(_ text: String) -> Int { text.trimmingCharacters(in: .whitespacesAndNewlines).utf16.count }
        guard (1...50).contains(length(title)), (1...240).contains(length(body)) else { return false }
        if translating, !(1...50).contains(length(translationTitle)) || !(1...240).contains(length(translationBody)) {
            return false
        }
        if coupon {
            guard (3...160).contains(length(couponDescription)), (1...720).contains(couponHours) else { return false }
            if fixedExpiry, couponExpiresAt <= Date.now || couponExpiresAt > Date.now.addingTimeInterval(365 * 86400) {
                return false
            }
        }
        return (1...365).contains(inactiveDays) && audienceReady && Self.audiences.contains(audience)
    }

    func request(id: String? = nil, version: Int? = nil) -> CampaignBody {
        func trimmed(_ text: String) -> String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
        let couponInput = coupon
            ? CampaignCoupon(
                description: trimmed(couponDescription), validHours: couponHours,
                expiresAt: fixedExpiry ? couponExpiresAt : nil)
            : nil
        let translationInput = translating
            ? CampaignTranslation(title: trimmed(translationTitle), body: trimmed(translationBody)) : nil
        return CampaignBody(
            id: id, version: version, name: name, title: trimmed(title), body: trimmed(body), locale: locale,
            audience: audience, inactiveDays: inactiveDays, tierIds: audience == "tiers" ? tierIds : [],
            customerCode: audience == "customer" ? customerCode : nil,
            branchId: audience == "joining_branch" ? branchId : nil,
            birthdayFrom: audience == "birthday_range" ? birthdayFrom : nil,
            birthdayTo: audience == "birthday_range" ? birthdayTo : nil,
            coupon: couponInput, translation: translationInput)
    }

    /// The query of `GET /api/campaigns/audience`, as the website builds it.
    var audienceQuery: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "audience", value: audience),
            URLQueryItem(name: "inactiveDays", value: String(inactiveDays)),
        ]
        if audience == "tiers", !tierIds.isEmpty {
            items.append(URLQueryItem(name: "tierIds", value: tierIds.joined(separator: ",")))
        }
        if audience == "customer", !customerCode.isEmpty {
            items.append(URLQueryItem(name: "customerCode", value: customerCode))
        }
        if audience == "joining_branch", !branchId.isEmpty {
            items.append(URLQueryItem(name: "branchId", value: branchId))
        }
        if audience == "birthday_range", Self.monthDay(birthdayFrom), Self.monthDay(birthdayTo) {
            items.append(URLQueryItem(name: "birthdayFrom", value: birthdayFrom))
            items.append(URLQueryItem(name: "birthdayTo", value: birthdayTo))
        }
        return items
    }

    static func validCode(_ code: String) -> Bool {
        code.range(of: "^(?!000000)[0-9]{6}$", options: .regularExpression) != nil
    }

    static func monthDay(_ value: String) -> Bool {
        value.range(of: "^(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$", options: .regularExpression) != nil
    }
}
