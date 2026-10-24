import ActivityKit

/// Where a Pager Ticket is. Raw values are the `state` the API sends in `content-state`
/// (`apps/api/src/modules/pager/pager-live-activity.ts`): `{ "state": "ready" }` or `{ "state": "ended" }`.
enum PagerState: String, Codable, Hashable {
    case waiting, ready, ended
}

/// The Pager Live Activity's data. The fixed fields and the state are tiny, far under ActivityKit's 4 KB limit.
/// The Business logo is not here: it is a file in the App Group (see `PagerLogo`).
struct PagerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var state: PagerState
    }

    var businessName: String
    /// Empty when the ticket has no Branch to show.
    var branchName: String
    var number: String
}
