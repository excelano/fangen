// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import CoreImage.CIFilterBuiltins
import SwiftUI

enum QRCode {
    private static let context = CIContext()

    /// One pixel per module, at error correction M. Scale it up with nearest-neighbor only.
    static func image(for text: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        return context.createCGImage(output, from: output.extent)
    }
}

/// A QR code on a white card with a quiet zone, the same in dark mode as in light.
struct QRCodeView: View {
    let text: String
    let accessibilityLabel: String

    var body: some View {
        if let image = QRCode.image(for: text) {
            Image(decorative: image, scale: 1)
                .interpolation(.none)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .padding(20)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
                .accessibilityElement()
                .accessibilityLabel(accessibilityLabel)
        }
    }
}
