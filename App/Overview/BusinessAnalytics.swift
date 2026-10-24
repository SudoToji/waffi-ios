import Foundation

/// One Overview tile: the count ever, in the last 7 Cairo days, and per day over the last 14 (`AnalyticsSeries` in waffi `packages/shared`).
struct AnalyticsSeries: Decodable, Equatable {
    let allTime: Int
    let last7Days: Int
    /// Oldest first, today last.
    let daily: [Int]

    static let zero = AnalyticsSeries(allTime: 0, last7Days: 0, daily: Array(repeating: 0, count: 14))
}

/// `GET /api/businesses/current/analytics[?branch=<id>]` (Owner and Manager), reduced to the numbers the Overview shows.
/// The answer holds more (returning customers, busy hours, sign-ups); the app ignores it for now.
struct BusinessAnalytics: Decodable, Equatable {
    /// New Customers.
    let customers: AnalyticsSeries
    /// Visit days: one per Customer per day with an Earn that was not undone.
    let visits: AnalyticsSeries
    let giftsRedeemed: AnalyticsSeries

    /// What the redacted loading state draws.
    static let placeholder = BusinessAnalytics(customers: .zero, visits: .zero, giftsRedeemed: .zero)

    /// Visit days of the last 7 days, today last: the bars.
    var weekBars: [Int] { Array(visits.daily.suffix(7)) }

    /// This week's visit days against the 7 days before, as a fraction (0.12 = up 12%). Nil when last week had none to compare with.
    var visitsChange: Double? {
        let before = visits.daily.dropLast(7).suffix(7).reduce(0, +)
        return before > 0 ? Double(visits.last7Days - before) / Double(before) : nil
    }
}
