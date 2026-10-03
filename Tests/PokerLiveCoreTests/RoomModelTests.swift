import XCTest
@testable import PokerLiveCore

final class RoomModelTests: XCTestCase {

    func testRoomWrittenByVersion1StillDecodes() throws {
        // Shape of a room created by v1.0 (no admins, no player ids on events)
        let json = """
        {
          "roomCode": "654321", "hostId": "host", "status": "active", "createdAt": 0,
          "totalPot": 100, "settlement": [],
          "players": [{"id": "p1", "name": "Dan", "avatar": "person", "totalBuyIn": 100, "buyInCount": 1, "profitLoss": -100}],
          "buyInTimeline": [{"id": "e1", "playerName": "Dan", "timestamp": 0, "amount": 100, "cumulativeTotal": 100, "isCashOut": false}]
        }
        """
        let room = try JSONDecoder().decode(GameRoom.self, from: Data(json.utf8))

        XCTAssertFalse(room.supportsSharedControl)
        XCTAssertEqual(room.allAdminIds, ["host"])
        XCTAssertTrue(room.isAdmin("host"))
        XCTAssertFalse(room.isAdmin("someone"))
        XCTAssertNil(room.buyInTimeline[0].playerId)
    }

    func testNewRoomRoundTrips() throws {
        var room = GameRoom(roomCode: "123456", hostId: "host", createdAt: Date(timeIntervalSince1970: 1_000))
        room.adminIds = ["host", "co"]
        room.adminNames = ["co": "Avi"]
        room.groupId = "ABC234"
        room.currencySymbol = "₪"

        let decoded = try JSONDecoder().decode(GameRoom.self, from: JSONEncoder().encode(room))
        XCTAssertEqual(decoded, room)
        XCTAssertEqual(decoded.schemaVersion, GameRoom.currentSchemaVersion)
        XCTAssertTrue(decoded.isAdmin("co"))
    }

    func testNewRoomStartsWithHostAsOnlyAdmin() {
        let room = GameRoom(roomCode: "123456", hostId: "host")
        XCTAssertEqual(room.adminIds, ["host"])
        XCTAssertTrue(room.isActive)
        XCTAssertFalse(room.isAdmin(nil))
    }

    func testLastActivityPrefersUpdatedAt() {
        var room = GameRoom(roomCode: "123456", hostId: "host", createdAt: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(room.lastActivity, Date(timeIntervalSince1970: 0))
        room.buyInTimeline = [BuyInEvent(id: "e", playerName: "Dan", timestamp: Date(timeIntervalSince1970: 50), amount: 1, cumulativeTotal: 1)]
        XCTAssertEqual(room.lastActivity, Date(timeIntervalSince1970: 50))
        room.updatedAt = Date(timeIntervalSince1970: 90)
        XCTAssertEqual(room.lastActivity, Date(timeIntervalSince1970: 90))
    }

    func testPresenceExpiresAfterMissedHeartbeats() {
        let now = Date(timeIntervalSince1970: 10_000)
        XCTAssertTrue(ViewerPresence(uid: "a", name: "Avi", lastSeen: now.addingTimeInterval(-60)).isActive(at: now))
        XCTAssertFalse(ViewerPresence(uid: "a", name: "Avi", lastSeen: now.addingTimeInterval(-600)).isActive(at: now))
        XCTAssertTrue(ViewerPresence(uid: "a", name: "Avi", lastSeen: nil).isActive(at: now), "a pending server timestamp counts as here")
    }

    func testRoomCodes() {
        XCTAssertTrue(RoomCode.isValid("123456"))
        XCTAssertFalse(RoomCode.isValid("1234"), "v1.0 asked for 4 digits, but codes are 6")
        XCTAssertFalse(RoomCode.isValid("12345a"))
        XCTAssertEqual(RoomCode.extract(from: "Room 123 456"), "123456")
        XCTAssertNil(RoomCode.extract(from: "12 34"))
    }
}

final class SettlementCalculatorTests: XCTestCase {

    func testSettlesWithFewestGreedyTransfers() {
        let transfers = SettlementCalculator.transfers(balances: [
            (name: "Dan", amount: -150), (name: "Avi", amount: 100), (name: "Noa", amount: 70), (name: "Eli", amount: -20),
        ])
        XCTAssertEqual(transfers, [
            .init(from: "Dan", to: "Avi", amount: 100),
            .init(from: "Dan", to: "Noa", amount: 50),
            .init(from: "Eli", to: "Noa", amount: 20),
        ])
    }

    func testBreakEvenPlayersAreLeftOut() {
        XCTAssertTrue(SettlementCalculator.transfers(balances: [(name: "Dan", amount: 0), (name: "Avi", amount: 0.004)]).isEmpty)
    }

    func testEveryDebtIsPaid() {
        let balances: [(name: String, amount: Double)] = [("A", -35), ("B", -65), ("C", 40), ("D", 60)]
        let transfers = SettlementCalculator.transfers(balances: balances)
        for (name, amount) in balances {
            let paid = transfers.filter { $0.from == name }.reduce(0) { $0 + $1.amount }
            let received = transfers.filter { $0.to == name }.reduce(0) { $0 + $1.amount }
            XCTAssertEqual(received - paid, amount, accuracy: 0.001, name)
        }
    }
}
