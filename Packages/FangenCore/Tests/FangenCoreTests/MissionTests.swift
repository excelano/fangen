// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import FangenCore

@Suite struct MissionTests {
    @Test func bundledLibraryLoads() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("../../../../Fangen/Resources/missions.json")
            .standardized
        let library = try MissionLibrary(json: Data(contentsOf: url))
        #expect(library.missions.count >= 29)
    }

    @Test func textNamesTheTarget() {
        #expect(testLibrary.missions[0].text(for: "Maya") == "Get Maya to say one.")
    }

    @Test func libraryRejectsBadFiles() {
        func load(_ json: String) throws {
            _ = try MissionLibrary(json: Data(json.utf8))
        }
        let mission = #"{ "id": "a", "kind": "say", "text": "Get {name} to say a." }"#
        #expect(throws: MissionLibraryError.unknownVersion) { try load(#"{ "version": 2, "missions": [\#(mission)] }"#) }
        #expect(throws: MissionLibraryError.empty) { try load(#"{ "version": 1, "missions": [] }"#) }
        #expect(throws: MissionLibraryError.duplicateID("a")) {
            try load(#"{ "version": 1, "missions": [\#(mission), \#(mission)] }"#)
        }
        #expect(throws: MissionLibraryError.missingName("b")) {
            try load(#"{ "version": 1, "missions": [{ "id": "b", "kind": "do", "text": "Do b." }] }"#)
        }
    }

    @Test func excludesTheCurrentMission() {
        var rng = SystemRandomNumberGenerator()
        let two = MissionLibrary(missions: Array(testLibrary.missions.prefix(2)))
        for _ in 0..<100 {
            #expect(two.mission(excluding: "m1", using: &rng).id == "m2")
        }
        let one = MissionLibrary(missions: Array(testLibrary.missions.prefix(1)))
        #expect(one.mission(excluding: "m1", using: &rng).id == "m1")
    }

    @Test func modesPickAssignments() {
        var rng = SystemRandomNumberGenerator()
        let tag = (0..<50).map { _ in testLibrary.assignment(for: .tag, excluding: nil, using: &rng) }
        let mission = (0..<50).map { _ in testLibrary.assignment(for: .mission, excluding: nil, using: &rng) }
        let mixed = (0..<200).map { _ in testLibrary.assignment(for: .mixed, excluding: nil, using: &rng) }
        #expect(tag.allSatisfy { $0 == .tag })
        #expect(mission.allSatisfy { $0.missionID != nil })
        #expect(mixed.contains(.tag) && mixed.contains { $0.missionID != nil })
    }
}
