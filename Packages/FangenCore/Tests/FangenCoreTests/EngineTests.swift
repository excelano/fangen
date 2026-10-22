// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import FangenCore

@Suite struct EngineTests {
    private let end = start.addingTimeInterval(3600)

    @Test func catchAdvancesToTheCaughtPlayersTarget() throws {
        var table = try Table(players: 4)
        let ring = table.ring
        let token = try table.eliminate(ring[1])
        #expect(table.apply(token, by: ring[0]) == .advanced(newTarget: ring[2]))
        #expect(table.games[ring[0]].currentTarget == ring[2])
        #expect(table.games[ring[0]].catchCount == 1)
    }

    @Test func lastCatchWins() throws {
        var table = try Table(players: 3)
        let ring = table.ring
        #expect(table.apply(try table.eliminate(ring[1]), by: ring[0]) == .advanced(newTarget: ring[2]))
        #expect(table.apply(try table.eliminate(ring[2]), by: ring[0]) == .won)
        #expect(table.games[ring[0]].status == .won)
        #expect(table.games[ring[0]].assignment == nil)
    }

    @Test func forfeitIsNotACatch() throws {
        var table = try Table(players: 4)
        let ring = table.ring
        #expect(table.apply(try table.eliminate(ring[1], .forfeit), by: ring[0]) == .advanced(newTarget: ring[2]))
        #expect(table.games[ring[0]].catchCount == 0)
        #expect(table.games[ring[0]].handovers.count == 1)
    }

    @Test func notYourTargetIsSavedOnce() throws {
        var table = try Table(players: 4)
        let ring = table.ring
        let token = try table.eliminate(ring[1])
        #expect(table.apply(token, by: ring[2]) == .notYourTarget)
        #expect(table.apply(token, by: ring[2]) == .notYourTarget)
        #expect(table.games[ring[2]].tokenInbox.count == 1)
    }

    @Test func rescanIsAlreadyCounted() throws {
        var table = try Table(players: 4)
        let ring = table.ring
        let token = try table.eliminate(ring[1])
        #expect(table.apply(token, by: ring[0]) == .advanced(newTarget: ring[2]))
        #expect(table.apply(token, by: ring[0]) == .alreadyCounted)
        #expect(table.games[ring[0]].tokenInbox.isEmpty)
    }

    @Test func eliminatedPlayerCannotApply() throws {
        var table = try Table(players: 4)
        let ring = table.ring
        let token = try table.eliminate(ring[1])
        _ = try table.eliminate(ring[0])
        #expect(table.apply(token, by: ring[0]) == .notAlive)
    }

    @Test func eliminateIsOneShot() throws {
        var table = try Table(players: 3)
        let token = try table.eliminate(0)
        #expect(throws: EliminateError.notAlive) { try table.eliminate(0, .forfeit) }
        #expect(table.games[0].myToken == token)
        #expect(table.games[0].status == .eliminated(.caught))
    }

    @Test func inboxCascades() throws {
        var table = try Table(players: 5)
        let ring = table.ring
        #expect(table.apply(try table.eliminate(ring[2], .forfeit), by: ring[0]) == .notYourTarget)
        #expect(table.apply(try table.eliminate(ring[1]), by: ring[0]) == .advanced(newTarget: ring[3]))
        #expect(table.games[ring[0]].tokenInbox.isEmpty)
        #expect(table.games[ring[0]].catchCount == 1)
    }

    @Test func cascadeCanWin() throws {
        var table = try Table(players: 3)
        let ring = table.ring
        #expect(table.apply(try table.eliminate(ring[2], .forfeit), by: ring[0]) == .notYourTarget)
        #expect(table.apply(try table.eliminate(ring[1]), by: ring[0]) == .won)
    }

    @Test func tokenSignedAtOrAfterTheEndIsRejected() throws {
        var table = try Table(players: 4, endDate: end)
        let ring = table.ring
        let late = try Token.signed(
            kind: .caught, gameID: table.payloads[0].gameID, caughtIndex: ring[1], caughtTarget: ring[2],
            caughtAt: end, key: table.keys[ring[1]], cert: table.payloads[ring[1]].myCert
        )
        #expect(table.apply(late, by: ring[0], at: end.addingTimeInterval(60)) == .afterTimeUp)
    }

    @Test func catchBeforeTheEndCountsDuringGrace() throws {
        var table = try Table(players: 4, endDate: end)
        let ring = table.ring
        let token = try table.eliminate(ring[1], at: end.addingTimeInterval(-60))
        let scanned = end.addingTimeInterval(LocalGame.scanGracePeriod - 60)
        #expect(table.apply(token, by: ring[0], at: scanned) == .advanced(newTarget: ring[2]))
    }

    @Test func scanningClosesAfterGrace() throws {
        var table = try Table(players: 4, endDate: end)
        let ring = table.ring
        let token = try table.eliminate(ring[1], at: end.addingTimeInterval(-60))
        let scanned = end.addingTimeInterval(LocalGame.scanGracePeriod)
        #expect(table.apply(token, by: ring[0], at: scanned) == .scanningClosed)
    }

    @Test func cannotEliminateAfterTheEnd() throws {
        var table = try Table(players: 4, endDate: end)
        #expect(throws: EliminateError.timeUp) { try table.eliminate(0, at: end) }
        #expect(table.games[0].isTimeUp(at: end))
        #expect(!table.games[0].isTimeUp(at: end.addingTimeInterval(-1)))
    }

    @Test func rerollOncePerTarget() throws {
        var table = try Table(players: 4)
        let ring = table.ring
        var rng = SystemRandomNumberGenerator()
        let before = table.games[ring[0]].assignment
        #expect(table.games[ring[0]].reroll(missions: testLibrary, using: &rng))
        #expect(table.games[ring[0]].assignment != before)
        #expect(!table.games[ring[0]].reroll(missions: testLibrary, using: &rng))
        _ = table.apply(try table.eliminate(ring[1]), by: ring[0])
        #expect(table.games[ring[0]].canReroll)
    }

    @Test func tagModeHasNoReroll() throws {
        let table = try Table(players: 3, mode: .tag)
        #expect(table.games[0].assignment == .tag)
        #expect(!table.games[0].canReroll)
    }

    @Test func dealMakesOneRing() throws {
        for players in [3, 12, 30] {
            let table = try Table(players: players)
            #expect(Set(table.ring).count == players)
            #expect(table.payloads.map(\.myIndex) == Array(0..<players))
            #expect(Set(table.payloads.map(\.gameID)).count == 1)
            #expect(Set(table.payloads.map(\.orgPub)).count == 1)
        }
    }

    @Test func dealValidates() throws {
        func deal(_ names: [String], title: String = "", playArea: String = "") throws {
            _ = try GameSetup(title: title, mode: .tag, playArea: playArea, names: names).deal()
        }
        let three = ["Maya", "Leo", "Sam"]
        #expect(throws: DealError.playerCount) { try deal(["Maya", "Leo"]) }
        #expect(throws: DealError.playerCount) { try deal((0...30).map { "P\($0)" }) }
        #expect(throws: DealError.names([1: .duplicate])) { try deal(["Maya", " maya ", "Leo"]) }
        #expect(throws: DealError.names([1: .empty])) { try deal(["Maya", "  ", "Leo"]) }
        #expect(throws: DealError.names([2: .tooLong])) { try deal(["Maya", "Leo", String(repeating: "s", count: 17)]) }
        #expect(throws: DealError.titleTooLong) { try deal(three, title: String(repeating: "t", count: 33)) }
        #expect(throws: DealError.playAreaTooLong) { try deal(three, playArea: String(repeating: "p", count: 49)) }
    }

    @Test func dealTrims() throws {
        let payloads = try GameSetup(title: " Park day ", mode: .tag, names: [" Maya ", "Leo", "Sam"]).deal()
        #expect(payloads[0].names[0] == "Maya")
        #expect(payloads[0].title == "Park day")
    }
}
