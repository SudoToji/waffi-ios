import Foundation

/// An open Pager Ticket as the dashboard sees it (`PagerTicketView` in waffi `packages/shared/src/contracts/pager.ts`).
struct StaffTicket: Decodable, Identifiable, Equatable {
    let id: String
    let number: String
    /// `waiting` or `ready`.
    let state: String
    let createdAt: Date
    let readyAt: Date?
    /// Whether any phone has opened or followed the ticket.
    let scanned: Bool
    /// `https://<host>/p/<token>`: what the QR carries.
    let qrLink: String
}

/// A Branch from `GET /api/branches` (an Owner's or Manager's view and a Staff Member's both have these fields).
struct StaffBranch: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    /// `working`, `locked` or `closed`; only a working Branch can be served at.
    let status: String
}
