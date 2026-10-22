// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public enum TokenKind: UInt8, Codable, Sendable {
    case caught = 0
    case forfeit = 1
}

public struct Token: Codable, Equatable, Sendable {
    private static let magic = Data("FT".utf8)
    private static let version: UInt8 = 1

    public let gameID: Data
    public let kind: TokenKind
    public let caughtIndex: Int
    public let caughtTarget: Int
    public let caughtAt: Date
    public let caughtPub: Data
    public let caughtCert: Data
    public let sig: Data

    public var link: String {
        Link.encode(encoded(), prefix: Link.tokenPrefix)
    }

    public init(link: String) throws {
        try self.init(decoding: Link.decode(link, prefix: Link.tokenPrefix))
    }

    init(
        gameID: Data, kind: TokenKind, caughtIndex: Int, caughtTarget: Int, caughtAt: Date,
        caughtPub: Data, caughtCert: Data, sig: Data
    ) {
        self.gameID = gameID
        self.kind = kind
        self.caughtIndex = caughtIndex
        self.caughtTarget = caughtTarget
        self.caughtAt = caughtAt
        self.caughtPub = caughtPub
        self.caughtCert = caughtCert
        self.sig = sig
    }

    func encoded() -> Data {
        var writer = ByteWriter()
        writer.bytes(Self.magic)
        writer.uint8(Self.version)
        writer.bytes(gameID)
        writer.uint8(kind.rawValue)
        writer.uint8(UInt8(caughtIndex))
        writer.uint8(UInt8(caughtTarget))
        writer.int64(Int64(caughtAt.timeIntervalSince1970))
        writer.bytes(caughtPub)
        writer.bytes(caughtCert)
        writer.bytes(sig)
        return writer.data
    }

    init(decoding data: Data) throws {
        var reader = ByteReader(data)
        guard try reader.bytes(2) == Self.magic else { throw DecodeError.badMagic }
        guard try reader.uint8() == Self.version else { throw DecodeError.unknownVersion }
        gameID = try reader.bytes(16)
        guard let kind = TokenKind(rawValue: try reader.uint8()) else { throw DecodeError.outOfRange }
        self.kind = kind
        caughtIndex = Int(try reader.uint8())
        caughtTarget = Int(try reader.uint8())
        caughtAt = Date(timeIntervalSince1970: TimeInterval(try reader.int64()))
        caughtPub = try reader.bytes(32)
        caughtCert = try reader.bytes(64)
        sig = try reader.bytes(64)
        try reader.finish()
    }
}
