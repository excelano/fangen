// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import SwiftUI

struct RootView: View {
    private struct PendingJoin: Identifiable {
        let id = UUID()
        let payload: JoinPayload
    }

    @Environment(GameStore.self) private var store
    @State private var path: [Data] = []
    @State private var scanning = false
    @State private var scannedLink: String?
    @State private var dealing = false
    @State private var pendingJoin: PendingJoin?
    @State private var message: String?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(newGame: { dealing = true }, joinGame: { scanning = true })
                .navigationDestination(for: Data.self) { GameView(gameID: $0) }
        }
        .sheet(isPresented: $scanning, onDismiss: openScannedLink) {
            ScanView { link in
                scannedLink = link
                scanning = false
            }
        }
        .sheet(item: $pendingJoin) { pending in
            JoinView(payload: pending.payload) { join(pending.payload) }
        }
        .fullScreenCover(isPresented: $dealing) {
            DealFlowView(
                onFinish: { organizerPayload in
                    dealing = false
                    if let organizerPayload { join(organizerPayload) }
                },
                onExpire: {
                    dealing = false
                    message = String(localized: "The deal was cancelled because Fangen was away for more than 10 minutes. Start a new deal.")
                }
            )
        }
        .onOpenURL { open($0.absoluteString) }
        .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") {}
        }
    }

    private func openScannedLink() {
        guard let link = scannedLink else { return }
        scannedLink = nil
        open(link)
    }

    private func open(_ link: String) {
        guard let parsed = try? FangenLink(link) else {
            message = String(localized: "That code isn't a working Fangen code.")
            return
        }
        guard case .join(let payload) = parsed else { return }
        switch store.check(payload) {
        case .new:
            pendingJoin = PendingJoin(payload: payload)
        case .alreadyJoined:
            message = String(localized: "You've already joined this game.")
            path = [payload.gameID]
        case .otherPlayerOnPhone:
            message = String(localized: "This device already has a player in this game.")
        }
    }

    private func join(_ payload: JoinPayload) {
        pendingJoin = nil
        do {
            try store.join(payload)
            path = [payload.gameID]
        } catch {
            message = String(localized: "Fangen couldn't save this game on this device. Try scanning the code again.")
        }
    }
}
