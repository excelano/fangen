// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)
//
// Threat model. Prevented: forging a catch without the caught player's phone; earning a catch on
// someone who isn't your target; learning who is seeking you; the organizer knowing the ring after
// the deal. Not prevented, and acceptable among friends: a player cooperating with a fake catch of
// themself; a bluffed tap getting someone to tap "I got got" (the bluffer's scan is rejected but the
// tapped player is out); a wrong clock on the caught player's phone skewing caughtAt; anyone who
// decodes a forfeit link learning whom that player was seeking; a player handing their phone to
// someone else; an organizer running a modified build.

import CryptoKit
import Foundation

enum SignedMessage {
    static func cert(gameID: Data, index: Int, publicKey: Data) -> Data {
        var writer = ByteWriter()
        writer.bytes(Data("FANGEN-CERT-v1".utf8))
        writer.bytes(gameID)
        writer.uint8(UInt8(index))
        writer.bytes(publicKey)
        return writer.data
    }

    static func token(gameID: Data, kind: TokenKind, caughtIndex: Int, caughtTarget: Int, caughtAt: Date) -> Data {
        var writer = ByteWriter()
        writer.bytes(Data("FANGEN-TOKEN-v1".utf8))
        writer.bytes(gameID)
        writer.uint8(kind.rawValue)
        writer.uint8(UInt8(caughtIndex))
        writer.uint8(UInt8(caughtTarget))
        writer.int64(Int64(caughtAt.timeIntervalSince1970))
        return writer.data
    }
}

extension Token {
    static func signed(
        kind: TokenKind, gameID: Data, caughtIndex: Int, caughtTarget: Int, caughtAt: Date,
        key: Curve25519.Signing.PrivateKey, cert: Data
    ) throws -> Token {
        let seconds = Date(timeIntervalSince1970: caughtAt.timeIntervalSince1970.rounded(.down))
        let message = SignedMessage.token(
            gameID: gameID, kind: kind, caughtIndex: caughtIndex, caughtTarget: caughtTarget, caughtAt: seconds
        )
        return Token(
            gameID: gameID, kind: kind, caughtIndex: caughtIndex, caughtTarget: caughtTarget, caughtAt: seconds,
            caughtPub: key.publicKey.rawRepresentation, caughtCert: cert, sig: try key.signature(for: message)
        )
    }

    func isValid(gameID: Data, orgPub: Data, playerCount: Int) -> Bool {
        guard self.gameID == gameID,
              caughtIndex < playerCount, caughtTarget < playerCount, caughtIndex != caughtTarget,
              let org = try? Curve25519.Signing.PublicKey(rawRepresentation: orgPub),
              let caught = try? Curve25519.Signing.PublicKey(rawRepresentation: caughtPub)
        else { return false }
        let certMessage = SignedMessage.cert(gameID: gameID, index: caughtIndex, publicKey: caughtPub)
        let tokenMessage = SignedMessage.token(
            gameID: gameID, kind: kind, caughtIndex: caughtIndex, caughtTarget: caughtTarget, caughtAt: caughtAt
        )
        return org.isValidSignature(caughtCert, for: certMessage) && caught.isValidSignature(sig, for: tokenMessage)
    }
}
