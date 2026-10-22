// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI
import UIKit

/// Screen brightness at maximum while the view is on screen and the app is active, restored after.
private struct FullBrightness: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @State private var saved: CGFloat?

    func body(content: Content) -> some View {
        content
            .onAppear(perform: raise)
            .onDisappear(perform: restore)
            .onChange(of: scenePhase) { _, phase in
                phase == .active ? raise() : restore()
            }
    }

    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
    }

    private func raise() {
        guard saved == nil, let screen else { return }
        saved = screen.brightness
        screen.brightness = 1
    }

    private func restore() {
        guard let saved, let screen else { return }
        screen.brightness = saved
        self.saved = nil
    }
}

extension View {
    func fullBrightness() -> some View {
        modifier(FullBrightness())
    }
}
