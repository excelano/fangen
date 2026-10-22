// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import SwiftUI

struct GameView: View {
    @Environment(GameStore.self) private var store
    let gameID: Data

    var body: some View {
        if let game = store.game(gameID) {
            List {
                if game.status == .alive {
                    Section {
                        TargetCard(game: game)
                            .listRowInsets(EdgeInsets())
                    }
                }
                Section {
                    LabeledContent("You are", value: game.names[game.myIndex])
                    LabeledContent("Status", value: game.statusText)
                    LabeledContent("Catches", value: game.catchCount, format: .number)
                    GameFacts(playerCount: game.names.count, mode: game.mode, playArea: game.playArea, endDate: game.endDate)
                }
                Section {
                    NavigationLink("Rules") { RulesView(mode: game.mode) }
                }
            }
            .navigationTitle(game.displayTitle)
        }
    }
}

/// Hidden until held, so nobody reads it over your shoulder. With VoiceOver, double-tap toggles it.
private struct TargetCard: View {
    let game: LocalGame
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 12) {
            if revealed {
                Text(game.names[game.currentTarget])
                    .font(.largeTitle.bold())
                if let text = game.assignmentText {
                    Text(text)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                }
            } else {
                Image(systemName: "eye.slash.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                Text(voiceOver ? "Double-tap to reveal your target" : "Tap and hold to reveal your target")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in revealed = true }
                .onEnded { _ in revealed = false }
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { revealed.toggle() }
    }
}

extension LocalGame {
    var assignmentText: String? {
        let name = names[currentTarget]
        switch assignment {
        case .tag:
            return playArea.isEmpty
                ? String(localized: "Tag \(name) on the shoulder.")
                : String(localized: "Tag \(name) on the shoulder. Play area: \(playArea)")
        case .mission(let mission):
            return mission.text(for: name)
        case nil:
            return nil
        }
    }
}
