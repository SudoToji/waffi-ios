import Foundation

/// Dates and text the Customers screens share. Days are Cairo calendar days, as on the website.
enum CustomerFormat {
    static let cairo = TimeZone(identifier: "Africa/Cairo") ?? .current

    static func day(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: cairo))
    }

    static func dayAndTime(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: cairo))
    }

    /// "Today", or the day; nil when there was no visit.
    static func lastVisit(_ date: Date?) -> String? {
        guard let date else { return nil }
        var calendar = Calendar.current
        calendar.timeZone = cairo
        return calendar.isDateInToday(date) ? String(localized: "Today") : day(date)
    }

    /// `YYYY-MM-DD` as a day on the phone's calendar.
    static func birthday(_ text: String) -> Date? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar(identifier: .gregorian).date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    static func birthdayText(_ date: Date) -> String {
        let parts = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 2000, parts.month ?? 1, parts.day ?? 1)
    }

    /// Keeps a phone number or an email in reading order inside right-to-left text.
    static func ltr(_ text: String) -> String { "\u{2066}" + text + "\u{2069}" }

    /// The phone as the API takes it (`+`, then 7 to 15 digits), or nil. A local Egyptian mobile number (01001234567) is +201001234567.
    static func phone(_ raw: String) -> String? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines).filter { !" -()".contains($0) }
        if text.count == 11, text.hasPrefix("0"), text.allSatisfy(\.isASCII), text.allSatisfy(\.isNumber) {
            text = "+20" + text.dropFirst()
        }
        return text.range(of: "^\+[1-9][0-9]{6,14}$", options: .regularExpression) == nil ? nil : text
    }

    /// A string of the String Catalog in another language than the phone's (the WhatsApp message is written in the Customer's).
    static func localized(_ key: String, language: String, _ arguments: CVarArg...) -> String {
        let bundle = Bundle.main.path(forResource: language, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        return String(format: bundle.localizedString(forKey: key, value: nil, table: nil), arguments: arguments)
    }
}
