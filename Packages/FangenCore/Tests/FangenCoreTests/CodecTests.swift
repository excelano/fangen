// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import FangenCore

@Suite struct CodecTests {
    private func payload(
        names: [String] = ["Maya", "Leo", "Sam"], title: String = "", playArea: String = "", endDate: Date? = nil
    ) throws -> JoinPayload {
        try GameSetup(title: title, mode: .mixed, playArea: playArea, endDate: endDate, names: names).deal()[1]
    }

    private func rebuilt(
        _ payload: JoinPayload, names: [String]? = nil, myIndex: Int? = nil, myFirstTarget: Int? = nil
    ) -> JoinPayload {
        JoinPayload(
            gameID: payload.gameID, title: payload.title, mode: payload.mode, endDate: payload.endDate,
            playArea: payload.playArea, names: names ?? payload.names, orgPub: payload.orgPub,
            myIndex: myIndex ?? payload.myIndex, myPriv: payload.myPriv, myCert: payload.myCert,
            myFirstTarget: myFirstTarget ?? payload.myFirstTarget
        )
    }

    @Test func joinRoundTrip() throws {
        let original = try payload(title: "Park day", playArea: "Memorial Park picnic area only", endDate: start)
        #expect(try JoinPayload(link: original.link) == original)
    }

    @Test func joinRoundTripWithEmptyOptionals() throws {
        let decoded = try JoinPayload(link: payload().link)
        #expect(decoded.title.isEmpty)
        #expect(decoded.playArea.isEmpty)
        #expect(decoded.endDate == nil)
    }

    @Test func worstCaseJoinSize() throws {
        let names = (0..<30).map { String(format: "%02d", $0) + String(repeating: "x", count: 14) }
        let original = try payload(
            names: names, title: String(repeating: "t", count: 32), playArea: String(repeating: "p", count: 48),
            endDate: start
        )
        #expect(original.encoded().count == 751)
        #expect(original.link.count == 1013)
        #expect(try JoinPayload(link: original.link) == original)
    }

    @Test func multibyteNamesAtTheLimit() throws {
        let names = ["ÄÖÜäöüßé", "名前名前名", "🦊🦊🦊🦊"]
        #expect(names.map(\.utf8.count) == [16, 15, 16])
        let original = try payload(names: names)
        #expect(try JoinPayload(link: original.link).names == names)
        #expect(throws: DealError.names([0: .tooLong])) { try payload(names: ["ÄÖÜäöüßéx", "Leo", "Sam"]) }
    }

    @Test func joinRejectsBadMagic() throws {
        var data = try payload().encoded()
        data[0] = UInt8(ascii: "X")
        #expect(throws: DecodeError.badMagic) { try JoinPayload(decoding: data) }
    }

    @Test func joinRejectsUnknownVersion() throws {
        var data = try payload().encoded()
        data[2] = 2
        #expect(throws: DecodeError.unknownVersion) { try JoinPayload(decoding: data) }
    }

    @Test func joinRejectsTruncatedInput() throws {
        let data = try payload(title: "Park day", endDate: start).encoded()
        for length in 0..<data.count {
            #expect(throws: DecodeError.truncated) { try JoinPayload(decoding: data.prefix(length)) }
        }
    }

    @Test func joinRejectsTrailingBytes() throws {
        let data = try payload().encoded() + [0]
        #expect(throws: DecodeError.trailingBytes) { try JoinPayload(decoding: data) }
    }

    @Test func joinRejectsOutOfRangeIndices() throws {
        let original = try payload()
        let badIndex = rebuilt(original, myIndex: 3).encoded()
        let badTarget = rebuilt(original, myFirstTarget: 3).encoded()
        let selfTarget = rebuilt(original, myFirstTarget: original.myIndex).encoded()
        let tooFew = rebuilt(original, names: ["Maya", "Leo"], myIndex: 0, myFirstTarget: 1).encoded()
        for data in [badIndex, badTarget, selfTarget, tooFew] {
            #expect(throws: DecodeError.outOfRange) { try JoinPayload(decoding: data) }
        }
    }

    @Test func joinRejectsDuplicateNames() throws {
        let data = rebuilt(try payload(), names: ["Maya", "maya", "Leo"]).encoded()
        #expect(throws: DecodeError.badNames) { try JoinPayload(decoding: data) }
    }

    @Test func tokenRoundTrip() throws {
        var table = try Table(players: 3)
        let token = try table.eliminate(0)
        #expect(token.encoded().count == 190)
        #expect(try Token(link: token.link) == token)
    }

    @Test func tokenRejectsMalformedInput() throws {
        var table = try Table(players: 3)
        let data = try table.eliminate(0).encoded()
        var magic = data
        magic[1] = UInt8(ascii: "J")
        var version = data
        version[2] = 2
        var kind = data
        kind[19] = 2
        #expect(throws: DecodeError.badMagic) { try Token(decoding: magic) }
        #expect(throws: DecodeError.unknownVersion) { try Token(decoding: version) }
        #expect(throws: DecodeError.outOfRange) { try Token(decoding: kind) }
        #expect(throws: DecodeError.trailingBytes) { try Token(decoding: data + [0]) }
        for length in 0..<data.count {
            #expect(throws: DecodeError.truncated) { try Token(decoding: data.prefix(length)) }
        }
    }

    @Test func linksAreBase64URLWithoutPadding() throws {
        var table = try Table(players: 3)
        let token = try table.eliminate(0)
        let joinBody = table.payloads[0].link.dropFirst("fangen://j/".count)
        let tokenBody = token.link.dropFirst("fangen://t/".count)
        for body in [joinBody, tokenBody] {
            #expect(!body.contains("=") && !body.contains("+") && !body.contains("/"))
        }
        #expect(throws: DecodeError.badLink) { try JoinPayload(link: token.link) }
        #expect(throws: DecodeError.badLink) { try Token(link: token.link + "=") }
        #expect(throws: DecodeError.badLink) { try Token(link: "https://example.com/t/abc") }
    }

    @Test func fangenLinkRoutesByPrefix() throws {
        var table = try Table(players: 3)
        let token = try table.eliminate(0)
        #expect(try FangenLink(table.payloads[1].link) == .join(table.payloads[1]))
        #expect(try FangenLink(token.link) == .token(token))
        #expect(throws: DecodeError.badLink) { try FangenLink("fangen://x/abc") }
    }
}
