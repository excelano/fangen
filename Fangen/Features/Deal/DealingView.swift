// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import SwiftUI

struct DealingView: View {
    @Binding var session: DealSession?
    let onFinish: () -> Void

    @State private var position = 0
    @State private var warningAboutLink = false
    @State private var sharingLink = false

    var body: some View {
        if let handouts = session?.handouts {
            handout(from: handouts)
        }
    }

    @ViewBuilder private func handout(from handouts: [JoinPayload]) -> some View {
        let payload = handouts[position]
        let name = payload.names[payload.myIndex]
        VStack(spacing: 20) {
            ProgressView(value: Double(position + 1), total: Double(handouts.count)) {
                Text("\(position + 1) of \(handouts.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 4) {
                Text("Hand to:")
                    .foregroundStyle(.secondary)
                Text(name)
                    .font(.largeTitle.bold())
            }
            QRCodeView(text: payload.link, accessibilityLabel: String(localized: "Join code for \(name)"))
                .fullBrightness()
            Button("Share link instead…") { warningAboutLink = true }
            Spacer()
            HStack {
                Button("Back") { position -= 1 }
                    .disabled(position == 0)
                Spacer()
                Button(position == handouts.count - 1 ? "Finish" : "Next") {
                    if position == handouts.count - 1 {
                        onFinish()
                    } else {
                        position += 1
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Dealing")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Share \(name)'s link?", isPresented: $warningAboutLink) {
            Button("Share") { sharingLink = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This link is \(name)'s secret key. Only send it to \(name), privately.")
        }
        .sheet(isPresented: $sharingLink) {
            ShareSheet(text: payload.link)
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
