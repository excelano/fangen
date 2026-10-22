// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import Foundation

/// What the organizer fills in before the deal. The organizer's own name, when they play, comes first.
struct DealDraft {
    struct NameRow: Identifiable {
        let id = UUID()
        var name = ""
    }

    var title = ""
    var mode: Mode = .tag
    var playArea = ""
    var hasEndDate = false
    var endDate = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
    var organizerPlays = true
    var myName = ""
    var others = [NameRow(), NameRow()]

    var names: [String] {
        ((organizerPlays ? [myName] : []) + others.map(\.name))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    var nameProblems: [Int: NameProblem] {
        FangenCore.nameProblems(names)
    }

    var otherNamesOffset: Int {
        organizerPlays ? 1 : 0
    }

    var titleTooLong: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).utf8.count > Limits.titleBytes
    }

    var playAreaTooLong: Bool {
        playArea.trimmingCharacters(in: .whitespacesAndNewlines).utf8.count > Limits.playAreaBytes
    }

    var isReady: Bool {
        Limits.players.contains(names.count) && nameProblems.isEmpty && !titleTooLong && !playAreaTooLong
    }

    #if DEBUG
    /// Every field at its limit, for testing the largest join code phone to phone.
    static var worstCase: DealDraft {
        var draft = DealDraft()
        draft.title = String(repeating: "T", count: Limits.titleBytes)
        draft.mode = .mixed
        draft.playArea = String(repeating: "P", count: Limits.playAreaBytes)
        draft.hasEndDate = true
        let names = (0..<Limits.players.upperBound).map { String(format: "Player number %02d", $0) }
        draft.myName = names[0]
        draft.others = names.dropFirst().map { NameRow(name: $0) }
        return draft
    }
    #endif

    var setup: GameSetup {
        GameSetup(
            title: title,
            mode: mode,
            playArea: mode == .mission ? "" : playArea,
            endDate: hasEndDate ? endDate : nil,
            names: names
        )
    }
}

/// Every player's private key, in memory only. Dropped when the deal finishes, is cancelled, or the
/// app stays in the background too long.
struct DealSession {
    let payloads: [JoinPayload]
    let organizerIndex: Int?

    var handouts: [JoinPayload] {
        payloads.filter { $0.myIndex != organizerIndex }
    }

    var organizerPayload: JoinPayload? {
        organizerIndex.map { payloads[$0] }
    }
}
