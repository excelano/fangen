// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public enum Mode: UInt8, Codable, Sendable, CaseIterable {
    case tag = 0
    case mission = 1
    case mixed = 2
}

public struct JoinPayload: Equatable, Sendable {
    private static let magic = Data("FJ".utf8)
    private static let version: UInt8 = 1

    public let gameID: Data
    public let title: String
    public let mode: Mode
    public let endDate: Date?
    public let playArea: String
    public let names: [String]
    public let orgPub: Data
    public let myIndex: Int
    public let myPriv: Data
    public let myCert: Data
    public let myFirstTarget: Int

    init(
        gameID: Data, title: String, mode: Mode, endDate: Date?, playArea: String, names: [String],
        orgPub: Data, myIndex: Int, myPriv: Data, myCert: Data, myFirstTarget: Int
    ) {
        self.gameID = gameID
        self.title = title
        self.mode = mode
        self.endDate = endDate
        self.playArea = playArea
        self.names = names
        self.orgPub = orgPub
        self.myIndex = myIndex
        self.myPriv = myPriv
        self.myCert = myCert
        self.myFirstTarget = myFirstTarget
    }

    public var link: String {
        Link.encode(encoded(), prefix: Link.joinPrefix)
    }

    public init(link: String) throws {
        try self.init(decoding: Link.decode(link, prefix: Link.joinPrefix))
    }

    func encoded() -> Data {
        var writer = ByteWriter()
        writer.bytes(Self.magic)
        writer.uint8(Self.version)
        writer.bytes(gameID)
        writer.string(title)
        writer.uint8(mode.rawValue)
        writer.int64(endDate.map { Int64($0.timeIntervalSince1970) } ?? 0)
        writer.string(playArea)
        writer.uint8(UInt8(names.count))
        names.forEach { writer.string($0) }
        writer.bytes(orgPub)
        writer.uint8(UInt8(myIndex))
        writer.bytes(myPriv)
        writer.bytes(myCert)
        writer.uint8(UInt8(myFirstTarget))
        return writer.data
    }

    init(decoding data: Data) throws {
        var reader = ByteReader(data)
        guard try reader.bytes(2) == Self.magic else { throw DecodeError.badMagic }
        guard try reader.uint8() == Self.version else { throw DecodeError.unknownVersion }
        gameID = try reader.bytes(16)
        title = try reader.string(maxBytes: Limits.titleBytes)
        guard let mode = Mode(rawValue: try reader.uint8()) else { throw DecodeError.outOfRange }
        self.mode = mode
        let end = try reader.int64()
        guard end >= 0 else { throw DecodeError.outOfRange }
        endDate = end == 0 ? nil : Date(timeIntervalSince1970: TimeInterval(end))
        playArea = try reader.string(maxBytes: Limits.playAreaBytes)
        let playerCount = Int(try reader.uint8())
        guard Limits.players.contains(playerCount) else { throw DecodeError.outOfRange }
        names = try (0..<playerCount).map { _ in try reader.string(maxBytes: Limits.nameBytes) }
        guard nameProblems(names).isEmpty else { throw DecodeError.badNames }
        orgPub = try reader.bytes(32)
        myIndex = Int(try reader.uint8())
        myPriv = try reader.bytes(32)
        myCert = try reader.bytes(64)
        myFirstTarget = Int(try reader.uint8())
        guard myIndex < playerCount, myFirstTarget < playerCount, myFirstTarget != myIndex
        else { throw DecodeError.outOfRange }
        try reader.finish()
    }
}
