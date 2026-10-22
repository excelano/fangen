// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import SwiftUI

struct RulesView: View {
    let mode: Mode?

    var body: some View {
        List {
            RulesSections(mode: mode)
        }
        .navigationTitle("Rules")
    }
}

/// The rules as list sections, for the Rules screen and for joining. `nil` shows every mode.
struct RulesSections: View {
    let mode: Mode?

    var body: some View {
        Section("How to catch") {
            ForEach(mode.map { [$0] } ?? Mode.allCases, id: \.self) { mode in
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title).font(.headline)
                    Text(mode.howToCatch)
                }
            }
        }
        Section("Play safe") {
            Text("Phones stay away at school. Catches happen in person; scan codes after school or on the weekend.")
            Text("Never play at school, in someone's home without being invited, in or around cars, or at anyone's job.")
            Text("Tag means a light tap on the shoulder. No grabbing, chasing into traffic, or hiding in places you shouldn't be.")
            Text("If someone says \"not now,\" respect it.")
            Text("If you get got, be a good sport and show your code.")
            if mode != .tag {
                Text("In long games, tag-style catches happen only at agreed group events.")
            }
        }
        Section("Winning") {
            Text("When you catch someone, you take over their target. Last one standing wins.")
            Text("If the game has an end date, whoever has the most catches when time runs out wins. Catches made before the end still count if they're scanned within 48 hours.")
        }
    }
}

extension Mode {
    var title: String {
        switch self {
        case .tag: String(localized: "Tag")
        case .mission: String(localized: "Missions")
        case .mixed: String(localized: "Mixed")
        }
    }

    var summary: String {
        switch self {
        case .tag: String(localized: "Short game, for a party, a park day or a campout.")
        case .mission: String(localized: "Long game, for a game that lasts days.")
        case .mixed: String(localized: "Each new target is randomly a tag or a mission.")
        }
    }

    var howToCatch: String {
        switch self {
        case .tag:
            String(localized: "Tap your target on the shoulder inside the play area.")
        case .mission:
            String(localized: "Each new target comes with a mission, like getting them to say \"pineapple.\" Pull it off in person without them catching on. Once they realize they've been got, they tap \"I got got\" and show their code.")
        case .mixed:
            String(localized: "Each new target is a tag or a mission, chosen at random.")
        }
    }
}
