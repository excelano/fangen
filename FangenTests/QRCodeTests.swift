// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import Testing
@testable import Fangen

@Suite struct QRCodeTests {
    /// QR version from the generated image: 17 + 4 × version modules, plus the generator's own margin.
    private func version(of text: String) throws -> Int {
        let one = try #require(QRCode.image(for: "A")).width
        let margin = (one - 21) / 2
        let width = try #require(QRCode.image(for: text)).width
        return (width - 2 * margin - 17) / 4
    }

    @Test func versionArithmeticHolds() throws {
        #expect(try version(of: "A") == 1)
    }

    @Test func worstCaseJoinCodeFitsVersion30() throws {
        let names = (0..<30).map { String(format: "%02d", $0) + String(repeating: "x", count: 14) }
        let setup = GameSetup(
            title: String(repeating: "t", count: 32), mode: .mixed, playArea: String(repeating: "p", count: 48),
            endDate: .now.addingTimeInterval(86_400), names: names
        )
        let link = try setup.deal()[0].link
        #expect(link.count == 1013)
        #expect(try version(of: link) <= 30)
    }
}
