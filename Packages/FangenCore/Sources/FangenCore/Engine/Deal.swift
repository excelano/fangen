// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import CryptoKit
import Foundation

public enum DealError: Error, Equatable, Sendable {
    case playerCount
    case names([Int: NameProblem])
    case titleTooLong
    case playAreaTooLong
}

public struct GameSetup: Sendable {
    public var title: String
    public var mode: Mode
    public var playArea: String
    public var endDate: Date?
    public var names: [String]

    public init(title: String = "", mode: Mode, playArea: String = "", endDate: Date? = nil, names: [String]) {
        self.title = title
        self.mode = mode
        self.playArea = playArea
        self.endDate = endDate
        self.names = names
    }

    /// One join payload per player, in name order. The ring and every private key exist only in the
    /// returned payloads; the caller holds them in memory for the deal and then drops them.
    public func deal() throws -> [JoinPayload] {
        let names = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let playArea = playArea.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Limits.players.contains(names.count) else { throw DealError.playerCount }
        let problems = nameProblems(names)
        guard problems.isEmpty else { throw DealError.names(problems) }
        guard title.utf8.count <= Limits.titleBytes else { throw DealError.titleTooLong }
        guard playArea.utf8.count <= Limits.playAreaBytes else { throw DealError.playAreaTooLong }

        var rng = SystemRandomNumberGenerator()
        let gameID = Data((0..<16).map { _ in UInt8.random(in: .min ... .max, using: &rng) })
        let ring = Array(names.indices).shuffled(using: &rng)
        var firstTarget = Array(repeating: 0, count: names.count)
        for k in ring.indices {
            firstTarget[ring[k]] = ring[(k + 1) % ring.count]
        }
        let endDate = endDate.map { Date(timeIntervalSince1970: $0.timeIntervalSince1970.rounded(.down)) }

        let orgKey = Curve25519.Signing.PrivateKey()
        return try names.indices.map { index in
            let key = Curve25519.Signing.PrivateKey()
            let publicKey = key.publicKey.rawRepresentation
            let cert = try orgKey.signature(for: SignedMessage.cert(gameID: gameID, index: index, publicKey: publicKey))
            return JoinPayload(
                gameID: gameID, title: title, mode: mode, endDate: endDate, playArea: playArea, names: names,
                orgPub: orgKey.publicKey.rawRepresentation, myIndex: index, myPriv: key.rawRepresentation,
                myCert: cert, myFirstTarget: firstTarget[index]
            )
        }
    }
}
