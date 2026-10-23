import ActivityKit

/// The Pager Live Activity's data. Placeholder: later tickets add the real fields.
struct PagerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var state: String
    }

    var businessName: String
    var branchName: String
    var number: String
}
