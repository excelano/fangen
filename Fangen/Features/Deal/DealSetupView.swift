// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import SwiftUI

struct DealSetupView: View {
    @Binding var draft: DealDraft
    let onNext: () -> Void

    var body: some View {
        let problems = draft.nameProblems
        Form {
            Section {
                TextField("Title (optional)", text: $draft.title)
                if draft.titleTooLong {
                    Problem("That title is too long.")
                }
            }
            Section {
                Picker("Mode", selection: $draft.mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Text(draft.mode.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if draft.mode != .mission {
                    TextField("Play area, like \"Memorial Park picnic area\"", text: $draft.playArea)
                    if draft.playAreaTooLong {
                        Problem("That play area is too long.")
                    }
                }
            }
            Section {
                Toggle("End date", isOn: $draft.hasEndDate)
                if draft.hasEndDate {
                    DatePicker("Ends", selection: $draft.endDate, in: Date.now...)
                }
            }
            Section {
                Toggle("I'm playing too", isOn: $draft.organizerPlays)
                if draft.organizerPlays {
                    TextField("Your name", text: $draft.myName)
                        .nameEntry()
                    NameProblemText(problems[0])
                }
            }
            Section {
                ForEach($draft.others) { $row in
                    let index = draft.others.firstIndex { $0.id == row.id }.map { $0 + draft.otherNamesOffset }
                    VStack(alignment: .leading) {
                        TextField("Player name", text: $row.name)
                            .nameEntry()
                        NameProblemText(index.flatMap { problems[$0] })
                    }
                }
                .onDelete { draft.others.remove(atOffsets: $0) }
                .onMove { draft.others.move(fromOffsets: $0, toOffset: $1) }
                Button("Add player", systemImage: "plus") {
                    draft.others.append(DealDraft.NameRow())
                }
                .disabled(draft.names.count >= Limits.players.upperBound)
            } header: {
                Text(draft.organizerPlays ? "Other players" : "Players")
            } footer: {
                Text("\(draft.names.count) players. A game needs \(Limits.players.lowerBound) to \(Limits.players.upperBound), each with a different name.")
            }
        }
        .navigationTitle("New game")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Next", action: onNext)
                    .disabled(!draft.isReady)
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            #if DEBUG
            ToolbarItem(placement: .bottomBar) {
                Button("Fill 30 test players") { draft = .worstCase }
            }
            #endif
        }
    }
}

private struct Problem: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.red)
    }
}

/// Empty names block the deal without a message; the footer already says every player needs one.
private struct NameProblemText: View {
    let problem: NameProblem?

    init(_ problem: NameProblem?) {
        self.problem = problem
    }

    var body: some View {
        switch problem {
        case .tooLong: Problem("That name is too long.")
        case .duplicate: Problem("Another player already has that name.")
        case .empty, nil: EmptyView()
        }
    }
}

private extension View {
    func nameEntry() -> some View {
        textInputAutocapitalization(.words)
            .autocorrectionDisabled()
    }
}
