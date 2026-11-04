// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        List {
            Section {
                Text("No accounts. No ads. No tracking. Nothing leaves your device.")
                    .font(.headline)
            }
            Section("Privacy") {
                Text("Fangen has no server and makes no network connections. Games, names and keys stay on this device, and the camera is used only to scan game codes.")
                Text("Deleting the app deletes your games. Restoring a device from a backup doesn't bring active games back.")
            }
            Section {
                LabeledContent("Version", value: version)
                LabeledContent("Made by", value: "excelano")
            }
        }
        .navigationTitle("About")
    }
}
