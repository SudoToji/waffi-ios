import ActivityKit
import Observation
import SwiftUI

/// One ticket the App Clip or the full app follows: reads it, keeps the Live Activity in step with it and registers the activity's push tokens.
@Observable @MainActor
final class PagerTicketModel: Identifiable {
    enum Phase {
        case loading
        case open(PagerTicket)
        case ended
    }

    let client: PagerClient
    let host: PagerHost
    private(set) var phase = Phase.loading
    /// The last read failed. Reading goes on every 5 seconds, so it clears itself.
    private(set) var connectionLost = false
    /// Live Activities are off for this app (or could not start): the on-screen status is all there is.
    private(set) var liveActivityOff = false

    @ObservationIgnored private var activity: Activity<PagerActivityAttributes>?
    /// The newest push token the server has not accepted yet; sent again after the next read.
    @ObservationIgnored private var pendingToken: Data?
    @ObservationIgnored private var logoFetched = false

    init(client: PagerClient, host: PagerHost) {
        self.client = client
        self.host = host
    }

    var id: String { client.token }

    var isEnded: Bool {
        if case .ended = phase { return true }
        return false
    }

    func refresh() async {
        do {
            let ticket = try await client.ticket()
            connectionLost = false
            guard ticket.state != .ended else {
                phase = .ended
                await endActivity()
                return
            }
            if !logoFetched {
                logoFetched = true
                if let path = ticket.logoUrl, let data = await client.logo(at: path) {
                    PagerLogo.save(data, forBusiness: ticket.businessName)
                }
            }
            phase = .open(ticket)
            await follow(ticket)
        } catch {
            connectionLost = true
        }
        await registerPendingToken()
    }

    /// Starts the Live Activity at once (or picks up the one an earlier scan of this ticket started) and keeps its state current.
    private func follow(_ ticket: PagerTicket) async {
        let state = PagerActivityAttributes.ContentState(state: ticket.state)
        if activity == nil {
            let existing = Activity<PagerActivityAttributes>.activities.first {
                $0.activityState == .active && $0.attributes.businessName == ticket.businessName && $0.attributes.number == ticket.number
            }
            if let existing {
                adopt(existing)
            } else if ActivityAuthorizationInfo().areActivitiesEnabled {
                let attributes = PagerActivityAttributes(
                    businessName: ticket.businessName, branchName: ticket.branchName, number: ticket.number)
                do {
                    adopt(try Activity.request(
                        attributes: attributes, content: ActivityContent(state: state, staleDate: nil), pushType: .token))
                } catch {
                    liveActivityOff = true
                    return
                }
            } else {
                liveActivityOff = true
                return
            }
        }
        liveActivityOff = false
        // A push may have been missed while the app was away; the read is the truth.
        if let activity, activity.content.state != state {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    private func adopt(_ activity: Activity<PagerActivityAttributes>) {
        self.activity = activity
        // Tokens rotate: every one is registered again. The sequence finishes when the activity ends.
        Task {
            for await token in activity.pushTokenUpdates {
                pendingToken = token
                await registerPendingToken()
            }
        }
    }

    private func registerPendingToken() async {
        guard let token = pendingToken else { return }
        do {
            try await client.registerLiveActivity(token: token, host: host)
        } catch PagerClientError.status(let code) where (400..<500).contains(code) && code != 429 {
            // Refused for good (the ticket ended, a bad request): do not send it again.
        } catch {
            return // Network or server trouble: tried again after the next read.
        }
        if pendingToken == token { pendingToken = nil }
    }

    private func endActivity() async {
        guard let activity else { return }
        self.activity = nil
        await activity.end(ActivityContent(state: .init(state: .ended), staleDate: nil), dismissalPolicy: .immediate)
    }
}
