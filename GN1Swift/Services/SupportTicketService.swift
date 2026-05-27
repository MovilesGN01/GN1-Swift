import Foundation
import FirebaseFirestore

// MARK: - Model

struct SupportTicket: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var status: String      // "pending_sync" | "open" | "resolved"
    var createdAt: Double
    var resolvedAt: Double?
}

// MARK: - Service
//
// Local storage strategy: JSON queue file (pending_support.json)
// Offline: ticket saved to JSON queue with status "pending_sync"
// Online:  syncPendingTickets() pushes queue to Firestore, clears synced entries
// Retry:   caller passes a completion(Bool) to know if sync succeeded

final class SupportTicketService {
    static let shared = SupportTicketService()
    private init() {}

    private let db = Firestore.firestore()

    private var pendingURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("pending_support.json")
    }

    // MARK: - Create (works offline)

    func createTicket(title: String, description: String) -> SupportTicket {
        let ticket = SupportTicket(
            id:          UUID().uuidString,
            title:       title,
            description: description,
            status:      "pending_sync",
            createdAt:   Date().timeIntervalSince1970,
            resolvedAt:  nil
        )
        var pending = loadPendingTickets()
        pending.append(ticket)
        savePending(pending)
        return ticket
    }

    // MARK: - Sync Pending to Firebase
    // Uses DispatchGroup so the completion fires only after ALL tickets are attempted.

    func syncPendingTickets(completion: ((Bool) -> Void)? = nil) {
        guard let userId = UserSession.shared.userId else {
            completion?(false)
            return
        }
        let pending = loadPendingTickets()
        guard !pending.isEmpty else {
            completion?(true)
            return
        }

        let group    = DispatchGroup()
        var syncedIds: [String] = []
        var anyFailure = false

        for ticket in pending {
            let syncStart = Date()
            group.enter()
            db.collection("support_tickets")
                .document(userId)
                .collection("tickets")
                .document(ticket.id)
                .setData([
                    "title":       ticket.title,
                    "description": ticket.description,
                    "status":      "open",
                    "createdAt":   ticket.createdAt
                ]) { [weak self] err in
                    let syncTime = Date().timeIntervalSince(syncStart) * 1000
                    let success  = err == nil
                    if !success { anyFailure = true }
                    AnalyticsService.shared.pendingTicketSynced(syncSuccess: success, syncTime: syncTime)
                    if success { syncedIds.append(ticket.id) }
                    self?.removeSyncedTickets(syncedIds)
                    group.leave()
                }
        }

        group.notify(queue: .main) {
            completion?(!anyFailure)
        }
    }

    // MARK: - Fetch History from Firebase

    func fetchTicketHistory(userId: String) async throws -> [SupportTicket] {
        try await withCheckedThrowingContinuation { cont in
            db.collection("support_tickets")
                .document(userId)
                .collection("tickets")
                .order(by: "createdAt", descending: true)
                .limit(to: 20)
                .getDocuments { snap, err in
                    if let err { cont.resume(throwing: err); return }
                    let tickets = snap?.documents.map { doc -> SupportTicket in
                        let d = doc.data()
                        return SupportTicket(
                            id:          doc.documentID,
                            title:       d["title"]       as? String ?? "",
                            description: d["description"] as? String ?? "",
                            status:      d["status"]      as? String ?? "open",
                            createdAt:   d["createdAt"]   as? Double ?? 0,
                            resolvedAt:  d["resolvedAt"]  as? Double
                        )
                    } ?? []
                    cont.resume(returning: tickets)
                }
        }
    }

    // MARK: - Local JSON Queue

    func loadPendingTickets() -> [SupportTicket] {
        guard let url  = pendingURL,
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([SupportTicket].self, from: data)) ?? []
    }

    private func savePending(_ tickets: [SupportTicket]) {
        guard let url  = pendingURL,
              let data = try? JSONEncoder().encode(tickets) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func removeSyncedTickets(_ syncedIds: [String]) {
        var remaining = loadPendingTickets()
        remaining.removeAll { syncedIds.contains($0.id) }
        savePending(remaining)
    }
}
