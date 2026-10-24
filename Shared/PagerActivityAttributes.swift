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
    /// The Business's Card style, fixed for the activity's life (a few bytes, far under ActivityKit's 4 KB limit).
    var style = PagerStyle.default
}

extension PagerActivityAttributes {
    /// An activity started by a build from before Card styles has no `style`; it keeps running with the default one.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        businessName = try c.decode(String.self, forKey: .businessName)
        branchName = try c.decode(String.self, forKey: .branchName)
        number = try c.decode(String.self, forKey: .number)
        style = try c.decodeIfPresent(PagerStyle.self, forKey: .style) ?? .default
    }

    /// "Business | Branch", or just the Business when there is no Branch.
    var title: String { branchName.isEmpty ? businessName : "\(businessName) | \(branchName)" }
}
