// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public enum FangenLink: Equatable, Sendable {
    case join(JoinPayload)
    case token(Token)

    public static let scheme = "fangen://"

    public init(_ link: String) throws {
        if link.hasPrefix(Link.joinPrefix) {
            self = .join(try JoinPayload(link: link))
        } else if link.hasPrefix(Link.tokenPrefix) {
            self = .token(try Token(link: link))
        } else {
            throw DecodeError.badLink
        }
    }
}
