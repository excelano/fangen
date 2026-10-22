// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import FangenCore
import SwiftUI

struct DealFlowView: View {
    private enum Step: Hashable {
        case review
        case dealing
        case done
    }

    static let backgroundLimit: TimeInterval = 10 * 60

    let onFinish: (JoinPayload?) -> Void
    let onExpire: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var draft = DealDraft()
    @State private var path: [Step] = []
    @State private var session: DealSession?
    @State private var organizerPayload: JoinPayload?
    @State private var backgroundedAt: Date?
    @State private var dealFailed = false
    @State private var confirmingCancel = false

    var body: some View {
        NavigationStack(path: $path) {
            DealSetupView(draft: $draft) { path.append(.review) }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                // Destinations are built once, when pushed, so each step reads state through a binding.
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .review:
                        DealReviewView(draft: $draft, onDeal: deal)
                    case .dealing:
                        DealingView(session: $session, onFinish: finishDealing)
                            .navigationBarBackButtonHidden()
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") { confirmingCancel = true }
                                }
                            }
                    case .done:
                        DealDoneView(organizerPayload: $organizerPayload, onDone: onFinish)
                            .navigationBarBackButtonHidden()
                    }
                }
        }
        .interactiveDismissDisabled()
        .confirmationDialog("Cancel the deal?", isPresented: $confirmingCancel, titleVisibility: .visible) {
            Button("Cancel the deal", role: .destructive) {
                session = nil
                dismiss()
            }
            Button("Keep dealing", role: .cancel) {}
        } message: {
            Text("Anyone who already scanned will need a new code from a new deal.")
        }
        .alert("Fangen couldn't deal this game.", isPresented: $dealFailed) {
            Button("OK") {}
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                backgroundedAt = .now
            case .active:
                if let backgroundedAt, session != nil, Date.now.timeIntervalSince(backgroundedAt) > Self.backgroundLimit {
                    session = nil
                    onExpire()
                }
                backgroundedAt = nil
            default:
                break
            }
        }
    }

    private func deal() {
        do {
            let payloads = try draft.setup.deal()
            session = DealSession(payloads: payloads, organizerIndex: draft.organizerPlays ? 0 : nil)
            path.append(.dealing)
        } catch {
            dealFailed = true
        }
    }

    private func finishDealing() {
        organizerPayload = session?.organizerPayload
        session = nil
        path.append(.done)
    }
}

private struct DealDoneView: View {
    @Binding var organizerPayload: JoinPayload?
    let onDone: (JoinPayload?) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            Text("Dealt!")
                .font(.largeTitle.bold())
            Text("This phone has forgotten the deal.")
                .foregroundStyle(.secondary)
            Spacer()
            Button(organizerPayload == nil ? "Done" : "Go to my game") { onDone(organizerPayload) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }
}
