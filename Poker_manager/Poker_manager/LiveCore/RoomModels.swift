import Foundation

// MARK: - Firestore-backed models for multiplayer room sync
//
// Everything in LiveCore is plain Foundation so it can be unit tested with
// `swift test` (see Package.swift at the repo root). The app compiles these
// same files directly.

/// A live game shared through Firestore at rooms/{roomCode}.
/// While a game is live, the room is the source of truth: the host and any
/// co-admins write actions to it (see RoomReducer) and everyone else watches.
nonisolated struct GameRoom: Codable, Equatable {
    static let currentSchemaVersion = 2

    var roomCode: String
    var hostId: String
    var status: String // "active" or "completed"
    var createdAt: Date
    var gameName: String?
    var totalPot: Double
    var players: [PlayerSnapshot]
    var buyInTimeline: [BuyInEvent]
    var settlement: [SettlementEntry]

    // Added in v1.1. Optional so rooms created by v1.0 still decode.
    var schemaVersion: Int?
    var adminIds: [String]?
    var adminNames: [String: String]?
    var groupId: String?
    var currencySymbol: String?
    var updatedAt: Date?
    var updatedBy: String?
    var endedAt: Date?

    init(roomCode: String, hostId: String, createdAt: Date = Date()) {
        self.roomCode = roomCode
        self.hostId = hostId
        self.status = "active"
        self.createdAt = createdAt
        self.totalPot = 0
        self.players = []
        self.buyInTimeline = []
        self.settlement = []
        self.schemaVersion = GameRoom.currentSchemaVersion
        self.adminIds = [hostId]
        self.adminNames = [:]
    }

    var isActive: Bool { status == "active" }

    /// Rooms created by v1.0 only support a single host writing snapshots.
    var supportsSharedControl: Bool { (schemaVersion ?? 1) >= 2 }

    /// Host first, then co-admins in the order they were added.
    var allAdminIds: [String] {
        var ids = [hostId]
        for id in adminIds ?? [] where !ids.contains(id) {
            ids.append(id)
        }
        return ids
    }

    func isAdmin(_ uid: String?) -> Bool {
        guard let uid else { return false }
        return allAdminIds.contains(uid)
    }

    /// Last time anything changed, used to hide abandoned rooms.
    var lastActivity: Date {
        updatedAt ?? buyInTimeline.map(\.timestamp).max() ?? createdAt
    }
}

nonisolated struct PlayerSnapshot: Codable, Identifiable, Equatable {
    var id: String // player UUID string
    var name: String
    var avatar: String
    var totalBuyIn: Double
    var buyInCount: Int
    var cashOut: Double?
    var profitLoss: Double

    var hasCashedOut: Bool { cashOut != nil }
}

nonisolated struct BuyInEvent: Codable, Identifiable, Equatable {
    var id: String
    var playerName: String
    var timestamp: Date
    var amount: Double
    var cumulativeTotal: Double
    var isCashOut: Bool?

    // Added in v1.1
    var playerId: String?
    /// Display name of the admin who recorded it
    var recordedBy: String?
}

nonisolated struct SettlementEntry: Codable, Identifiable, Equatable {
    var id: String
    var from: String
    var to: String
    var amount: Double

    init(from: String, to: String, amount: Double) {
        self.id = UUID().uuidString
        self.from = from
        self.to = to
        self.amount = amount
    }
}

/// One person watching a room, stored at rooms/{code}/viewers/{uid}.
nonisolated struct ViewerPresence: Codable, Identifiable, Equatable {
    /// How long after the last heartbeat someone still counts as watching.
    static let activeWindow: TimeInterval = 150

    var uid: String
    var name: String
    /// Server timestamp; nil while a local write is still pending.
    var lastSeen: Date?

    var id: String { uid }

    func isActive(at now: Date) -> Bool {
        guard let lastSeen else { return true }
        return now.timeIntervalSince(lastSeen) < ViewerPresence.activeWindow
    }
}

nonisolated enum RoomCode {
    static let length = 6

    static func isValid(_ code: String) -> Bool {
        code.count == length && code.allSatisfy(\.isASCIIDigit)
    }

    /// Pulls a room code out of pasted text such as "Room 123 456".
    static func extract(from text: String) -> String? {
        let digits = text.filter(\.isASCIIDigit)
        return digits.count == length ? digits : nil
    }
}

private extension Character {
    nonisolated var isASCIIDigit: Bool { isASCII && isNumber }
}
