import XCTest
@testable import PokerLiveCore

final class RoomReducerTests: XCTestCase {

    let host = "host-uid"
    let coAdmin = "coadmin-uid"
    let viewer = "viewer-uid"
    let t0 = Date(timeIntervalSince1970: 1_790_000_000)

    private func makeRoom() -> GameRoom {
        GameRoom(roomCode: "123456", hostId: host, createdAt: t0)
    }

    private func buyIn(_ id: String, player: String, name: String, _ amount: Double) -> RoomAction {
        .buyIn(eventId: id, playerId: player, playerName: name, avatar: "person", amount: amount)
    }

    /// Applies actions in order, one second apart, like a Firestore transaction would.
    private func run(_ actions: [(RoomAction, String)], on room: GameRoom) throws -> GameRoom {
        var room = room
        for (index, (action, uid)) in actions.enumerated() {
            room = try RoomReducer.apply(action, to: room, by: uid, actorName: uid, at: t0.addingTimeInterval(Double(index + 1)))
        }
        return room
    }

    // MARK: - Live updates

    func testBuyInsUpdatePotPlayersAndTimeline() throws {
        let room = try run([
            (buyIn("b1", player: "p1", name: "Dan", 100), host),
            (buyIn("b2", player: "p2", name: "Avi", 50), host),
            (buyIn("b3", player: "p1", name: "Dan", 100), host),
        ], on: makeRoom())

        XCTAssertEqual(room.totalPot, 250)
        XCTAssertEqual(room.players.map(\.name), ["Dan", "Avi"])
        XCTAssertEqual(room.players[0].totalBuyIn, 200)
        XCTAssertEqual(room.players[0].buyInCount, 2)
        XCTAssertEqual(room.players[0].profitLoss, -200)
        XCTAssertEqual(room.buyInTimeline.map(\.cumulativeTotal), [100, 150, 250])
        XCTAssertEqual(room.buyInTimeline.last?.recordedBy, host)
        XCTAssertEqual(room.updatedBy, host)
    }

    func testReplayingABuyInIsIgnored() throws {
        let once = try run([(buyIn("b1", player: "p1", name: "Dan", 100), host)], on: makeRoom())
        let twice = try RoomReducer.apply(buyIn("b1", player: "p1", name: "Dan", 100), to: once, by: host, actorName: nil, at: t0.addingTimeInterval(60))

        XCTAssertEqual(twice, once, "a retried or echoed action must not add a second buy-in")
    }

    func testCashOutMidGameAndCorrection() throws {
        var room = try run([
            (buyIn("b1", player: "p1", name: "Dan", 100), host),
            (.cashOut(playerId: "p1", amount: 180), host),
        ], on: makeRoom())

        XCTAssertEqual(room.players[0].cashOut, 180)
        XCTAssertEqual(room.players[0].profitLoss, 80)
        XCTAssertEqual(room.totalPot, -80, "pot is buy-ins minus chips taken off the table")

        room = try RoomReducer.apply(.cashOut(playerId: "p1", amount: 150), to: room, by: host, actorName: nil, at: t0.addingTimeInterval(10))
        XCTAssertEqual(room.buyInTimeline.filter { $0.isCashOut == true }.count, 1, "a correction replaces the cash-out")
        XCTAssertEqual(room.players[0].cashOut, 150)
    }

    func testCashOutForUnknownPlayerIsRejected() {
        XCTAssertThrowsError(try RoomReducer.apply(.cashOut(playerId: "ghost", amount: 10), to: makeRoom(), by: host, actorName: nil, at: t0)) {
            XCTAssertEqual($0 as? RoomActionError, .unknownPlayer)
        }
    }

    func testInvalidAmountsAreRejected() {
        for amount in [0, -5, Double.nan, Double.infinity] {
            XCTAssertThrowsError(try RoomReducer.apply(buyIn("b", player: "p1", name: "Dan", amount), to: makeRoom(), by: host, actorName: nil, at: t0))
        }
    }

    // MARK: - Co-admins

    func testViewerCannotChangeTheGame() {
        XCTAssertThrowsError(try RoomReducer.apply(buyIn("b1", player: "p1", name: "Dan", 100), to: makeRoom(), by: viewer, actorName: nil, at: t0)) {
            XCTAssertEqual($0 as? RoomActionError, .notAdmin)
        }
    }

    func testCoAdminTakesOverWhenHostLeaves() throws {
        // Host starts the game and promotes a player, then leaves the table.
        let beforeHostLeft = try run([
            (buyIn("b1", player: "p1", name: "Dan", 100), host),
            (buyIn("b2", player: "p2", name: "Avi", 100), host),
            (.addAdmin(uid: coAdmin, name: "Avi"), host),
        ], on: makeRoom())
        XCTAssertTrue(beforeHostLeft.isAdmin(coAdmin))
        XCTAssertEqual(beforeHostLeft.adminNames?[coAdmin], "Avi")

        // Everything after this point is done only by the co-admin.
        let finished = try run([
            (buyIn("b3", player: "p2", name: "Avi", 100), coAdmin),
            (buyIn("b4", player: "p3", name: "Noa", 100), coAdmin),
            (.cashOut(playerId: "p1", amount: 0), coAdmin),
            (.endGame(finalCashOuts: ["p2": 250, "p3": 150]), coAdmin),
        ], on: beforeHostLeft)

        XCTAssertFalse(finished.isActive)
        XCTAssertEqual(finished.updatedBy, coAdmin)
        XCTAssertEqual(finished.players.map(\.profitLoss), [-100, 50, 50])
        XCTAssertEqual(finished.totalPot, 0)
        XCTAssertEqual(finished.settlement.map { "\($0.from)->\($0.to):\(Int($0.amount))" }.sorted(),
                       ["Dan->Avi:50", "Dan->Noa:50"])
        XCTAssertEqual(finished.endedAt, finished.updatedAt)
    }

    func testCoAdminCanAddAdminsButNotRemoveThem() throws {
        let room = try run([
            (.addAdmin(uid: coAdmin, name: "Avi"), host),
            (.addAdmin(uid: viewer, name: "Noa"), coAdmin),
        ], on: makeRoom())
        XCTAssertEqual(room.allAdminIds, [host, coAdmin, viewer])

        XCTAssertThrowsError(try RoomReducer.apply(.removeAdmin(uid: viewer), to: room, by: coAdmin, actorName: nil, at: t0)) {
            XCTAssertEqual($0 as? RoomActionError, .notHost)
        }
    }

    func testHostRemovesAdminAndCannotBeRemoved() throws {
        var room = try run([(.addAdmin(uid: coAdmin, name: "Avi"), host)], on: makeRoom())
        room = try RoomReducer.apply(.removeAdmin(uid: coAdmin), to: room, by: host, actorName: nil, at: t0)

        XCTAssertFalse(room.isAdmin(coAdmin))
        XCTAssertNil(room.adminNames?[coAdmin])
        XCTAssertThrowsError(try RoomReducer.apply(buyIn("b1", player: "p1", name: "Dan", 1), to: room, by: coAdmin, actorName: nil, at: t0))
        XCTAssertThrowsError(try RoomReducer.apply(.removeAdmin(uid: host), to: room, by: host, actorName: nil, at: t0)) {
            XCTAssertEqual($0 as? RoomActionError, .cannotRemoveHost)
        }
    }

    func testTwoAdminsTappingAtOnceBothCount() throws {
        // Both phones start from the same room. Firestore transactions retry
        // the loser against the winner's result, which is what applying in
        // sequence models.
        let base = try run([(.addAdmin(uid: coAdmin, name: "Avi"), host)], on: makeRoom())
        let hostFirst = try RoomReducer.apply(buyIn("h1", player: "p1", name: "Dan", 100), to: base, by: host, actorName: nil, at: t0)
        let merged = try RoomReducer.apply(buyIn("c1", player: "p2", name: "Avi", 50), to: hostFirst, by: coAdmin, actorName: nil, at: t0)

        XCTAssertEqual(Set(merged.buyInTimeline.map(\.id)), ["h1", "c1"])
        XCTAssertEqual(merged.totalPot, 150)
        XCTAssertEqual(merged.buyInTimeline.map(\.id), ["h1", "c1"], "same timestamp keeps arrival order")
    }

    // MARK: - Game lifecycle

    func testEndedGameRejectsChangesUntilReopened() throws {
        var room = try run([
            (buyIn("b1", player: "p1", name: "Dan", 100), host),
            (.endGame(finalCashOuts: ["p1": 100]), host),
        ], on: makeRoom())

        XCTAssertThrowsError(try RoomReducer.apply(buyIn("b2", player: "p1", name: "Dan", 100), to: room, by: host, actorName: nil, at: t0)) {
            XCTAssertEqual($0 as? RoomActionError, .gameEnded)
        }

        room = try RoomReducer.apply(.reopen, to: room, by: host, actorName: nil, at: t0.addingTimeInterval(100))
        XCTAssertTrue(room.isActive)
        XCTAssertNil(room.endedAt)
        XCTAssertTrue(room.settlement.isEmpty)
        XCTAssertNoThrow(try RoomReducer.apply(buyIn("b2", player: "p1", name: "Dan", 100), to: room, by: host, actorName: nil, at: t0))
    }

    func testLegacyRoomIsReadOnlyForNewActions() {
        var legacy = makeRoom()
        legacy.schemaVersion = nil
        legacy.adminIds = nil
        XCTAssertThrowsError(try RoomReducer.apply(buyIn("b1", player: "p1", name: "Dan", 100), to: legacy, by: host, actorName: nil, at: t0)) {
            XCTAssertEqual($0 as? RoomActionError, .legacyRoom)
        }
    }

    func testTimelineIsSortedAndRunningTotalRecomputed() {
        var room = makeRoom()
        room.players = [PlayerSnapshot(id: "p1", name: "Dan", avatar: "person", totalBuyIn: 0, buyInCount: 0, cashOut: nil, profitLoss: 0)]
        room.buyInTimeline = [
            BuyInEvent(id: "late", playerName: "Dan", timestamp: t0.addingTimeInterval(20), amount: 50, cumulativeTotal: 0, isCashOut: false, playerId: "p1"),
            BuyInEvent(id: "early", playerName: "Dan", timestamp: t0, amount: 100, cumulativeTotal: 0, isCashOut: false, playerId: "p1"),
        ]
        RoomReducer.recompute(&room)

        XCTAssertEqual(room.buyInTimeline.map(\.id), ["early", "late"])
        XCTAssertEqual(room.buyInTimeline.map(\.cumulativeTotal), [100, 150])
        XCTAssertEqual(room.players[0].totalBuyIn, 150)
    }
}
