// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public enum DecodeError: Error, Equatable, Sendable {
    case badLink
    case badMagic
    case unknownVersion
    case truncated
    case trailingBytes
    case badString
    case outOfRange
    case badNames
}

struct ByteWriter {
    private(set) var data = Data()

    mutating func uint8(_ value: UInt8) {
        data.append(value)
    }

    mutating func int64(_ value: Int64) {
        withUnsafeBytes(of: value.bigEndian) { data.append(contentsOf: $0) }
    }

    mutating func bytes(_ value: Data) {
        data.append(value)
    }

    mutating func string(_ value: String) {
        let utf8 = Data(value.utf8)
        precondition(utf8.count <= Int(UInt8.max))
        uint8(UInt8(utf8.count))
        bytes(utf8)
    }
}

struct ByteReader {
    private let data: Data
    private var offset = 0

    init(_ data: Data) {
        self.data = Data(data)
    }

    mutating func bytes(_ count: Int) throws -> Data {
        guard data.count - offset >= count else { throw DecodeError.truncated }
        defer { offset += count }
        return data.subdata(in: offset..<offset + count)
    }

    mutating func uint8() throws -> UInt8 {
        try bytes(1)[0]
    }

    mutating func int64() throws -> Int64 {
        try bytes(8).reduce(0) { $0 << 8 | Int64($1) }
    }

    mutating func string(maxBytes: Int) throws -> String {
        let count = Int(try uint8())
        guard count <= maxBytes,
              let value = String(data: try bytes(count), encoding: .utf8)
        else { throw DecodeError.badString }
        return value
    }

    func finish() throws {
        guard offset == data.count else { throw DecodeError.trailingBytes }
    }
}

enum Link {
    static let joinPrefix = "fangen://j/"
    static let tokenPrefix = "fangen://t/"

    static func encode(_ data: Data, prefix: String) -> String {
        let base64URL = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return prefix + base64URL
    }

    static func decode(_ link: String, prefix: String) throws -> Data {
        guard link.hasPrefix(prefix) else { throw DecodeError.badLink }
        let body = link.dropFirst(prefix.count)
        guard body.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") })
        else { throw DecodeError.badLink }
        let base64 = body
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padded = base64 + String(repeating: "=", count: (4 - base64.count % 4) % 4)
        guard let data = Data(base64Encoded: padded) else { throw DecodeError.badLink }
        return data
    }
}
