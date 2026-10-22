// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public enum MissionKind: String, Codable, Sendable {
    case say, give, ask, get, `do`
}

public struct Mission: Codable, Equatable, Sendable {
    public let id: String
    public let kind: MissionKind
    public let text: String

    public func text(for name: String) -> String {
        text.replacingOccurrences(of: "{name}", with: name)
    }
}

public enum Assignment: Codable, Equatable, Sendable {
    case tag
    case mission(Mission)
}

public enum MissionLibraryError: Error, Equatable, Sendable {
    case unknownVersion
    case empty
    case duplicateID(String)
    case missingName(String)
}

public struct MissionLibrary: Sendable {
    public let missions: [Mission]

    init(missions: [Mission]) {
        self.missions = missions
    }

    public init(json: Data) throws {
        struct File: Decodable {
            let version: Int
            let missions: [Mission]
        }
        let file = try JSONDecoder().decode(File.self, from: json)
        guard file.version == 1 else { throw MissionLibraryError.unknownVersion }
        guard !file.missions.isEmpty else { throw MissionLibraryError.empty }
        var ids: Set<String> = []
        for mission in file.missions {
            guard ids.insert(mission.id).inserted else { throw MissionLibraryError.duplicateID(mission.id) }
            guard mission.text.contains("{name}") else { throw MissionLibraryError.missingName(mission.id) }
        }
        missions = file.missions
    }

    func mission(excluding id: String?, using rng: inout some RandomNumberGenerator) -> Mission {
        let others = missions.filter { $0.id != id }
        return (others.isEmpty ? missions : others).randomElement(using: &rng)!
    }

    func assignment(for mode: Mode, excluding id: String?, using rng: inout some RandomNumberGenerator) -> Assignment {
        switch mode {
        case .tag:
            .tag
        case .mission:
            .mission(mission(excluding: id, using: &rng))
        case .mixed:
            Bool.random(using: &rng) ? .tag : .mission(mission(excluding: id, using: &rng))
        }
    }
}
