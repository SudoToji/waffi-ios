import Foundation

enum PagerLayout: String, Codable, Hashable {
    /// A: logo row and ring.
    case ring
    /// B: ticket stub.
    case stub
    /// C: progress track.
    case track
    /// D: Arabic first, right to left.
    case arabic
}

enum PagerWording: String, Codable, Hashable {
    case order, coffee, car, turn
}

enum PagerBackground: String, Codable, Hashable {
    case solid
    /// The system's own see-through lock-screen material.
    case transparent
}

/// The Card style a Business chose (`PagerStyle` in waffi `packages/shared/src/contracts/pager-style.ts`): the same four values the
/// public ticket read answers. It travels in the Live Activity's fixed attributes, so it stays tiny.
struct PagerStyle: Codable, Hashable {
    var layout = PagerLayout.ring
    var wording = PagerWording.order
    /// `#RRGGBB`, as chosen: contrast against the card is the drawing's job (`PagerPalette`).
    var color = PagerColors.fallback
    var background = PagerBackground.solid

    /// What an older API (one that sends no style) and an unreadable style both get: Waffi teal, generic wording, layout A.
    static let `default` = PagerStyle()
}

extension PagerStyle {
    /// Reads each part on its own: a value this build does not know (a newer API) falls back to the default for that part
    /// instead of failing the whole ticket.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        layout = (try? c.decode(PagerLayout.self, forKey: .layout)) ?? .ring
        wording = (try? c.decode(PagerWording.self, forKey: .wording)) ?? .order
        let hex = (try? c.decode(String.self, forKey: .color))?.uppercased()
        color = hex.flatMap { PagerColors.isValid($0) ? $0 : nil } ?? PagerColors.fallback
        background = (try? c.decode(PagerBackground.self, forKey: .background)) ?? .solid
    }
}
