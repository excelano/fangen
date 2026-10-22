// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import CryptoKit
import Foundation

public enum Status: Codable, Equatable, Sendable {
    case alive
    case eliminated(TokenKind)
    case won
}

public struct Handover: Codable, Equatable, Sendable {
    public let caughtIndex: Int
    public let kind: TokenKind
    public let date: Date
}

public enum ApplyResult: Equatable, Sendable {
    case advanced(newTarget: Int)
    case won
    case notYourTarget
    case alreadyCounted
    case afterTimeUp
    case scanningClosed
    case invalid
    case notAlive
}

public enum EliminateError: Error, Equatable, Sendable {
    case notAlive
    case timeUp
}

public struct LocalGame: Codable, Equatable, Sendable {
    public static let scanGracePeriod: TimeInterval = 48 * 60 * 60

    public let gameID: Data
    public let title: String
    public let mode: Mode
    public let endDate: Date?
    public let playArea: String
    public let names: [String]
    public let orgPub: Data
    public let myIndex: Int
    public let myCert: Data
    public private(set) var status: Status
    public private(set) var currentTarget: Int
    public private(set) var assignment: Assignment?
    public private(set) var rerollUsed: Bool
    public private(set) var handovers: [Handover]
    public private(set) var tokenInbox: [Token]
    public private(set) var myToken: Token?
    public let joinedAt: Date

    /// The payload's private key is not kept here; the caller stores it in the Keychain.
    public init(joining payload: JoinPayload, at now: Date, missions: MissionLibrary, using rng: inout some RandomNumberGenerator) {
        gameID = payload.gameID
        title = payload.title
        mode = payload.mode
        endDate = payload.endDate
        playArea = payload.playArea
        names = payload.names
        orgPub = payload.orgPub
        myIndex = payload.myIndex
        myCert = payload.myCert
        status = .alive
        currentTarget = payload.myFirstTarget
        assignment = missions.assignment(for: payload.mode, excluding: nil, using: &rng)
        rerollUsed = false
        handovers = []
        tokenInbox = []
        myToken = nil
        joinedAt = now
    }

    public var catchCount: Int {
        handovers.filter { $0.kind == .caught }.count
    }

    public func isTimeUp(at now: Date) -> Bool {
        endDate.map { now >= $0 } ?? false
    }

    public func isScanningOpen(at now: Date) -> Bool {
        endDate.map { now < $0.addingTimeInterval(Self.scanGracePeriod) } ?? true
    }

    public var canReroll: Bool {
        guard status == .alive, !rerollUsed, case .mission = assignment else { return false }
        return true
    }

    public mutating func apply(
        _ token: Token, at now: Date, missions: MissionLibrary, using rng: inout some RandomNumberGenerator
    ) -> ApplyResult {
        guard status == .alive else { return .notAlive }
        guard token.isValid(gameID: gameID, orgPub: orgPub, playerCount: names.count) else { return .invalid }
        guard isScanningOpen(at: now) else { return .scanningClosed }
        if let endDate, token.caughtAt >= endDate { return .afterTimeUp }
        if handovers.contains(where: { $0.caughtIndex == token.caughtIndex }) { return .alreadyCounted }
        guard token.caughtIndex == currentTarget else {
            if !tokenInbox.contains(where: { $0.caughtIndex == token.caughtIndex }) {
                tokenInbox.append(token)
            }
            return .notYourTarget
        }

        var next = token
        while true {
            handovers.append(Handover(caughtIndex: next.caughtIndex, kind: next.kind, date: next.caughtAt))
            currentTarget = next.caughtTarget
            if currentTarget == myIndex {
                status = .won
                assignment = nil
                return .won
            }
            guard let queued = tokenInbox.firstIndex(where: { $0.caughtIndex == currentTarget }) else { break }
            next = tokenInbox.remove(at: queued)
        }
        assignment = missions.assignment(for: mode, excluding: assignment?.missionID, using: &rng)
        rerollUsed = false
        return .advanced(newTarget: currentTarget)
    }

    public mutating func reroll(missions: MissionLibrary, using rng: inout some RandomNumberGenerator) -> Bool {
        guard canReroll else { return false }
        assignment = .mission(missions.mission(excluding: assignment?.missionID, using: &rng))
        rerollUsed = true
        return true
    }

    /// Irreversible: the UI confirms before calling. A player produces at most one token, ever.
    public mutating func eliminate(
        _ kind: TokenKind, signingWith key: Curve25519.Signing.PrivateKey, at now: Date
    ) throws -> Token {
        guard status == .alive else { throw EliminateError.notAlive }
        guard !isTimeUp(at: now) else { throw EliminateError.timeUp }
        let token = try Token.signed(
            kind: kind, gameID: gameID, caughtIndex: myIndex, caughtTarget: currentTarget, caughtAt: now,
            key: key, cert: myCert
        )
        myToken = token
        status = .eliminated(kind)
        assignment = nil
        return token
    }
}

extension Assignment {
    var missionID: String? {
        guard case .mission(let mission) = self else { return nil }
        return mission.id
    }
}
