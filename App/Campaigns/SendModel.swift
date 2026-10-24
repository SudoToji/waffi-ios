import Foundation
import Observation

/// Sending a message now, after one confirmation that shows who gets it: a draft as it is, or "Send again" of a sent one.
/// Send again never touches the sent campaign (the API has no resend): it makes a new draft with the same message, audience
/// and coupon, under a new id, and sends that. The id and the new draft are kept, so a retry after a failure makes no second draft.
@Observable @MainActor
final class SendModel: Identifiable {
    enum Source {
        case draft(Campaign)
        case again(Campaign)
    }

    let id = UUID()
    let source: Source
    private let api: ApiClient
    private let newId = UUID().uuidString.lowercased()
    private var created: Campaign?

    private(set) var counts: CampaignCounts?
    private(set) var countError: ApiError?
    private(set) var sending = false
    private(set) var error: ApiError?

    init(api: ApiClient, source: Source, counts: CampaignCounts? = nil) {
        self.api = api
        self.source = source
        self.counts = counts
    }

    /// The message being sent.
    var campaign: Campaign {
        switch source {
        case .draft(let campaign), .again(let campaign): campaign
        }
    }

    /// Who gets it: the Customers who agreed to marketing.
    var recipients: Int? { counts?.optedIn }

    func loadCounts() async {
        countError = nil
        do {
            counts = try await api.get("api/campaigns/audience", query: MessageForm(campaign).audienceQuery)
        } catch let failure as ApiError {
            countError = failure
        } catch {}
    }

    /// True when the campaign was queued for delivery.
    func send() async -> Bool {
        guard !sending else { return false }
        sending = true
        error = nil
        defer { sending = false }
        do {
            let target: Campaign
            switch source {
            case .draft(let draft):
                target = draft
            case .again(let sentBefore):
                if let created {
                    target = created
                } else {
                    let form = MessageForm(sentBefore, fresh: true)
                    target = try await api.post("api/campaigns", json: form.request(id: newId))
                    created = target
                }
            }
            let _: Campaign = try await api.post("api/campaigns/\(target.id)/send-now", json: VersionBody(version: target.version))
            return true
        } catch let failure as ApiError {
            error = failure
        } catch {}
        return false
    }
}
