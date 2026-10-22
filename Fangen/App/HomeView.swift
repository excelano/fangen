// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import SwiftUI

struct HomeView: View {
    @Environment(GameStore.self) private var store
    let newGame: () -> Void
    let joinGame: () -> Void

    var body: some View {
        List {
            if store.games.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("One person deals the game and hands everyone a secret code.")
                        Text("You only ever know your own target.")
                        Text("Catch them, scan their code, and take their target. Last one standing wins.")
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Section("Your games") {
                    ForEach(store.games) { game in
                        NavigationLink(value: game.gameID) {
                            GameRow(game: game)
                        }
                    }
                }
            }
            Section {
                Button("New game", systemImage: "plus.circle.fill", action: newGame)
                Button("Join a game", systemImage: "qrcode.viewfinder", action: joinGame)
            }
            Section {
                NavigationLink("Rules") { RulesView(mode: nil) }
                NavigationLink("About") { AboutView() }
            }
        }
        .navigationTitle("Fangen")
    }
}

private struct GameRow: View {
    let game: LocalGame

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(game.displayTitle)
                .font(.headline)
            Text("\(game.names.count) players · \(game.statusText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

extension LocalGame {
    var displayTitle: String {
        title.isEmpty ? String(localized: "Untitled game") : title
    }

    var statusText: String {
        switch status {
        case .alive: String(localized: "Playing")
        case .eliminated: String(localized: "Out")
        case .won: String(localized: "Won")
        }
    }
}
