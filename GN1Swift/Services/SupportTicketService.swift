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

// Offline-capable support ticket management:
//   Create offline → save to pending_support.json → sync to Firebase on reconnect
final class SupportTicketService {
    static let shared = SupportTicketService()

    private let db = Firestore.firestore()

    private var pendingURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("pending_support.json")
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

    func syncPendingTickets() {
        guard let userId = UserSession.shared.userId else { return }
        let pending = loadPendingTickets()
        guard !pending.isEmpty else { return }

        var syncedIds: [String] = []

        for ticket in pending {
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
                    guard err == nil else { return }
                    syncedIds.append(ticket.id)
                    self?.removeSyncedTickets(syncedIds)
                }
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

    // MARK: - Local JSON Persistence

    func loadPendingTickets() -> [SupportTicket] {
        guard let url = pendingURL,
              let data = try? Data(contentsOf: url),
              let tickets = try? JSONDecoder().decode([SupportTicket].self, from: data)
        else { return [] }
        return tickets
    }

    private func savePending(_ tickets: [SupportTicket]) {
        guard let url = pendingURL,
              let data = try? JSONEncoder().encode(tickets) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func removeSyncedTickets(_ syncedIds: [String]) {
        var remaining = loadPendingTickets()
        remaining.removeAll { syncedIds.contains($0.id) }
        savePending(remaining)
    }
}
