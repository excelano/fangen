// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import SwiftUI

struct JoinView: View {
    let payload: JoinPayload
    let onJoin: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("You are \(payload.names[payload.myIndex])")
                        .font(.title.bold())
                    GameFacts(
                        playerCount: payload.names.count, mode: payload.mode, playArea: payload.playArea,
                        endDate: payload.endDate
                    )
                }
                RulesSections(mode: payload.mode)
                Section {
                    Button("I'll play by the rules. Join!", action: onJoin)
                        .font(.headline)
                }
            }
            .navigationTitle(payload.title.isEmpty ? String(localized: "Join game") : payload.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct GameFacts: View {
    let playerCount: Int
    let mode: Mode
    let playArea: String
    let endDate: Date?

    var body: some View {
        LabeledContent("Players", value: playerCount, format: .number)
        LabeledContent("Mode", value: mode.title)
        if !playArea.isEmpty {
            LabeledContent("Play area", value: playArea)
        }
        if let endDate {
            LabeledContent("Ends", value: endDate, format: .dateTime.weekday().month().day().hour().minute())
        }
    }
}
