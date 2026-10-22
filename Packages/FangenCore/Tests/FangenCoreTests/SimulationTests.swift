// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import FangenCore

/// Full games under the global view. Forfeit tokens go to a shared group chat that each player
/// catches up on at random times, so seekers sometimes catch someone through an unread forfeit and
/// the inbox has to cascade. A caught player whose scan comes back "not your target" posts their
/// token in the chat too (§8.5); without that, the token dies if its holder is caught.
@Suite struct SimulationTests {
    @Test(arguments: Limits.players)
    func fullGames(players: Int) throws {
        for _ in 0..<500 {
            try playGame(players: players)
        }
    }

    private func playGame(players: Int) throws {
        var rng = SystemRandomNumberGenerator()
        var table = try Table(players: players, mode: Mode.allCases.randomElement(using: &rng)!)
        var chat: [Token] = []
        var read = Array(repeating: 0, count: players)
        var forfeits = 0

        func catchUp(_ player: Int) {
            while read[player] < chat.count {
                #expect(table.apply(chat[read[player]], by: player) != .invalid)
                read[player] += 1
            }
        }

        func checkInvariants() {
            let alive = table.alive
            for seeker in alive {
                #expect(table.games[seeker].currentTarget != seeker)
                for token in table.pendingTokens(for: seeker) {
                    let held = table.games[seeker].tokenInbox.contains(token) || chat[read[seeker]...].contains(token)
                    #expect(held, "seeker \(seeker) cannot resolve player \(token.caughtIndex)")
                }
                let target = table.effectiveTarget(of: seeker)
                #expect(table.games[target].status == .alive && target != seeker)
            }
            for player in alive {
                #expect(alive.filter { table.effectiveTarget(of: $0) == player }.count == 1)
            }
        }

        var someoneWon: Bool { table.games.contains { $0.status == .won } }

        while !someoneWon {
            let alive = table.alive
            if alive.count == 1 {
                catchUp(alive[0])
                break
            }
            let caught = alive.randomElement(using: &rng)!
            let seeker = try #require(alive.first { table.effectiveTarget(of: $0) == caught })
            let kind: TokenKind = Double.random(in: 0..<1, using: &rng) < 0.15 ? .forfeit : .caught
            let token = try table.eliminate(caught, kind)
            switch kind {
            case .caught:
                let direct = table.games[seeker].currentTarget == caught
                let result = table.apply(token, by: seeker)
                if direct {
                    #expect(result == .won || result == .advanced(newTarget: table.games[seeker].currentTarget))
                } else {
                    #expect(result == .notYourTarget)
                    chat.append(token)
                }
            case .forfeit:
                forfeits += 1
                chat.append(token)
            }
            for player in table.alive where Bool.random(using: &rng) {
                catchUp(player)
            }
            if !someoneWon && table.alive.count > 1 {
                checkInvariants()
            }
        }

        #expect(table.games.filter { $0.status == .won }.count == 1)
        #expect(table.games.map(\.catchCount).reduce(0, +) == players - 1 - forfeits)
    }
}
