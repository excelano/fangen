// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public enum Limits {
    public static let players = 3...30
    public static let nameBytes = 16
    public static let titleBytes = 32
    public static let playAreaBytes = 48
}

public enum NameProblem: Equatable, Sendable {
    case empty
    case tooLong
    case duplicate
}

/// Problems keyed by name index. A duplicate is reported on its later occurrence; names compare case-insensitively.
public func nameProblems(_ names: [String]) -> [Int: NameProblem] {
    var problems: [Int: NameProblem] = [:]
    var seen: Set<String> = []
    for (index, name) in names.enumerated() {
        if name.isEmpty {
            problems[index] = .empty
        } else if name.utf8.count > Limits.nameBytes {
            problems[index] = .tooLong
        } else if !seen.insert(name.lowercased()).inserted {
            problems[index] = .duplicate
        }
    }
    return problems
}
