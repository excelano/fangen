// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import SwiftUI

struct DealReviewView: View {
    @Binding var draft: DealDraft
    let onDeal: () -> Void

    var body: some View {
        let setup = draft.setup
        List {
            Section {
                if !setup.title.isEmpty {
                    LabeledContent("Title", value: setup.title)
                }
                GameFacts(playerCount: setup.names.count, mode: setup.mode, playArea: setup.playArea, endDate: setup.endDate)
            }
            Section("Players") {
                ForEach(Array(setup.names.enumerated()), id: \.offset) { index, name in
                    Text(index == 0 && draft.organizerPlays ? "\(name) (you)" : name)
                }
            }
            Section {
                Label("Keep the app open until everyone has scanned.", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                Text("The deal lives only in memory. If Fangen is closed, or stays in the background for more than 10 minutes, the deal is lost and you'll start over.")
                    .foregroundStyle(.secondary)
            }
            Section {
                Button("Deal", action: onDeal)
                    .font(.headline)
            }
        }
        .navigationTitle("Review")
    }
}
