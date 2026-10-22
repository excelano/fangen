// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import FangenCore

@Suite struct CryptoTests {
    private func isValid(_ token: Token, in table: Table) -> Bool {
        let payload = table.payloads[0]
        return token.isValid(gameID: payload.gameID, orgPub: payload.orgPub, playerCount: payload.names.count)
    }

    @Test func signedTokenVerifies() throws {
        var table = try Table(players: 3)
        #expect(isValid(try table.eliminate(1), in: table))
    }

    @Test func tamperingWithAnyByteFails() throws {
        var table = try Table(players: 5)
        let data = try table.eliminate(2, .forfeit).encoded()
        for index in data.indices {
            var tampered = data
            tampered[index] ^= 0x01
            if let token = try? Token(decoding: tampered) {
                #expect(!isValid(token, in: table), "byte \(index)")
            }
        }
    }

    @Test func tokenFromAnotherGameFails() throws {
        var table = try Table(players: 3)
        var other = try Table(players: 3)
        let token = try other.eliminate(0)
        #expect(!isValid(token, in: table))
        #expect(table.apply(token, by: table.ring.last!) == .invalid)
    }

    @Test func certFromAnotherOrganizerFails() throws {
        var table = try Table(players: 3)
        let other = try Table(players: 3)
        let token = try table.eliminate(0)
        let payload = table.payloads[0]
        #expect(!token.isValid(gameID: payload.gameID, orgPub: other.payloads[0].orgPub, playerCount: 3))
    }
}
