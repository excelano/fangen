// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import CryptoKit
import Foundation
@testable import FangenCore

let start = Date(timeIntervalSince1970: 1_800_000_000)

let testLibrary = MissionLibrary(missions: [
    Mission(id: "m1", kind: .say, text: "Get {name} to say one."),
    Mission(id: "m2", kind: .ask, text: "Get {name} to answer two."),
    Mission(id: "m3", kind: .do, text: "Get {name} to do three."),
])

/// Every player's phone in one place: the test-only global view.
struct Table {
    let payloads: [JoinPayload]
    let keys: [Curve25519.Signing.PrivateKey]
    var games: [LocalGame]

    init(players: Int, mode: Mode = .mission, endDate: Date? = nil) throws {
        let names = (0..<players).map { "Player \($0)" }
        payloads = try GameSetup(mode: mode, endDate: endDate, names: names).deal()
        keys = try payloads.map { try Curve25519.Signing.PrivateKey(rawRepresentation: $0.myPriv) }
        var rng = SystemRandomNumberGenerator()
        games = payloads.map { LocalGame(joining: $0, at: start, missions: testLibrary, using: &rng) }
    }

    /// Players in ring order from player 0: ring[k] seeks ring[k + 1].
    var ring: [Int] {
        var ring = [0]
        while ring.count < payloads.count {
            ring.append(payloads[ring.last!].myFirstTarget)
        }
        return ring
    }

    var alive: [Int] {
        games.indices.filter { games[$0].status == .alive }
    }

    /// Tokens of the out players between a seeker and their effective target, in order.
    func pendingTokens(for seeker: Int) -> [Token] {
        var tokens: [Token] = []
        var target = games[seeker].currentTarget
        while games[target].status != .alive, let token = games[target].myToken, tokens.count < games.count {
            tokens.append(token)
            target = token.caughtTarget
        }
        return tokens
    }

    func effectiveTarget(of seeker: Int) -> Int {
        pendingTokens(for: seeker).last?.caughtTarget ?? games[seeker].currentTarget
    }

    mutating func eliminate(_ player: Int, _ kind: TokenKind = .caught, at now: Date = start) throws -> Token {
        try games[player].eliminate(kind, signingWith: keys[player], at: now)
    }

    mutating func apply(_ token: Token, by player: Int, at now: Date = start) -> ApplyResult {
        var rng = SystemRandomNumberGenerator()
        return games[player].apply(token, at: now, missions: testLibrary, using: &rng)
    }
}
