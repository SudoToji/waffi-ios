import Foundation

/// What the add and edit sheets collect.
struct CustomerForm: Equatable {
    var name = ""
    var email = ""
    var phone = ""
    var hasBirthday = false
    var birthday = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now
    /// `en` or `ar`.
    var locale = "en"
    /// "Asked to stop marketing messages": the only change to marketing a Business may record.
    var stopMarketing = false

    init() {}

    init(_ customer: Customer) {
        name = customer.name
        email = customer.email ?? ""
        phone = customer.phone ?? ""
        if let text = customer.birthday, let date = CustomerFormat.birthday(text) {
            hasBirthday = true
            birthday = date
        }
        locale = customer.preferredLocale
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    var trimmedPhone: String { phone.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The first thing wrong with the entries, as the API's own code (it would refuse the same way), or nil.
    var problem: String? {
        if !(2...255).contains(trimmedName.count) { return "VALIDATION" }
        if trimmedEmail.isEmpty && trimmedPhone.isEmpty { return "CUSTOMER_CONTACT_REQUIRED" }
        if !trimmedPhone.isEmpty && CustomerFormat.phone(trimmedPhone) == nil { return "PHONE_INVALID" }
        return nil
    }
}

/// `PUT /api/customers/:id`: the edit form sends all five fields, `null` clearing an email, phone or birthday.
struct CustomerUpdateBody: Encodable {
    let name: String
    let email: String?
    let phone: String?
    let birthday: String?
    let preferredLocale: String
    /// Only ever `false`, and only when asked.
    let marketingConsent: Bool?

    init(_ form: CustomerForm) {
        name = form.trimmedName
        email = form.trimmedEmail.isEmpty ? nil : form.trimmedEmail
        phone = form.trimmedPhone.isEmpty ? nil : CustomerFormat.phone(form.trimmedPhone)
        birthday = form.hasBirthday ? CustomerFormat.birthdayText(form.birthday) : nil
        preferredLocale = form.locale
        marketingConsent = form.stopMarketing ? false : nil
    }

    private enum Keys: String, CodingKey { case name, email, phone, birthday, preferredLocale, marketingConsent }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(phone, forKey: .phone)
        try container.encode(birthday, forKey: .birthday)
        try container.encode(preferredLocale, forKey: .preferredLocale)
        try container.encodeIfPresent(marketingConsent, forKey: .marketingConsent)
    }
}

/// `POST /api/customers`: a name, an email or phone, and the language. No birthday.
struct CustomerCreateBody: Encodable {
    let name: String
    let email: String?
    let phone: String?
    let preferredLocale: String

    init(_ form: CustomerForm) {
        name = form.trimmedName
        email = form.trimmedEmail.isEmpty ? nil : form.trimmedEmail
        phone = form.trimmedPhone.isEmpty ? nil : CustomerFormat.phone(form.trimmedPhone)
        preferredLocale = form.locale
    }
}

/// `PUT /api/customer-tiers/customers/:id`: `tierId` null clears the tier.
struct TierAssignBody: Encodable {
    let tierId: String?
    let tellCustomer: Bool?

    private enum Keys: String, CodingKey { case tierId, tellCustomer }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(tierId, forKey: .tierId)
        try container.encodeIfPresent(tellCustomer, forKey: .tellCustomer)
    }
}
