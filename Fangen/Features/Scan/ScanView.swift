// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import AVFoundation
import FangenCore
import SwiftUI
import VisionKit

struct ScanView: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var access = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Scan a code")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    #if DEBUG
                    ToolbarItem(placement: .bottomBar) {
                        PasteButton(payloadType: String.self) { strings in
                            guard let link = strings.first?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                            Task { @MainActor in onScan(link) }
                        }
                    }
                    #endif
                }
        }
    }

    @ViewBuilder private var content: some View {
        if !DataScannerViewController.isSupported {
            ContentUnavailableView(
                "No camera scanning",
                systemImage: "camera.metering.unknown",
                description: Text("This device can't scan codes.")
            )
        } else if access == .notDetermined {
            ProgressView()
                .task {
                    _ = await AVCaptureDevice.requestAccess(for: .video)
                    access = AVCaptureDevice.authorizationStatus(for: .video)
                }
        } else if DataScannerViewController.isAvailable {
            DataScanner(onScan: onScan)
                .ignoresSafeArea()
        } else {
            ContentUnavailableView {
                Label("Camera is off", systemImage: "camera.fill")
            } description: {
                Text("Fangen needs the camera to scan game codes. Turn it on in Settings.")
            } actions: {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
        }
    }
}

/// Reports the first QR code that holds a Fangen link and ignores everything else.
private struct DataScanner: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .accurate,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        if !scanner.isScanning {
            try? scanner.startScanning()
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    @MainActor final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private var reported = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]
        ) {
            guard !reported else { return }
            for item in addedItems {
                if case .barcode(let code) = item, let link = code.payloadStringValue, link.hasPrefix(FangenLink.scheme) {
                    reported = true
                    onScan(link)
                    return
                }
            }
        }
    }
}
