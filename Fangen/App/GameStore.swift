// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import Foundation
import Observation

@MainActor @Observable
final class GameStore {
    enum JoinCheck {
        case new
        case alreadyJoined
        case otherPlayerOnPhone
    }

    private(set) var games: [LocalGame] = []
    let missions: MissionLibrary
    private let fileURL = URL.applicationSupportDirectory.appending(path: "games.json")

    init() {
        let missionsURL = Bundle.main.url(forResource: "missions", withExtension: "json")!
        missions = try! MissionLibrary(json: Data(contentsOf: missionsURL))
        if let data = try? Data(contentsOf: fileURL) {
            games = (try? JSONDecoder().decode([LocalGame].self, from: data)) ?? []
        }
    }

    func game(_ gameID: Data) -> LocalGame? {
        games.first { $0.gameID == gameID }
    }

    func check(_ payload: JoinPayload) -> JoinCheck {
        guard let existing = game(payload.gameID) else { return .new }
        return existing.myIndex == payload.myIndex ? .alreadyJoined : .otherPlayerOnPhone
    }

    func join(_ payload: JoinPayload) throws {
        guard check(payload) == .new else { return }
        try Keychain.savePlayerKey(payload.myPriv, gameID: payload.gameID)
        var rng = SystemRandomNumberGenerator()
        games.append(LocalGame(joining: payload, at: .now, missions: missions, using: &rng))
        try save()
    }

    private func save() throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try JSONEncoder().encode(games).write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}
