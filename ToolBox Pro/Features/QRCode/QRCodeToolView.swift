import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins
import UIKit

struct QRCodeToolView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore
    enum Mode: Int {
        case generate = 0
        case scan = 1
    }

    enum GenerateKind: String, CaseIterable, Identifiable {
        case text
        case url
        case wifi
        case phone

        var id: String { rawValue }

        var title: String {
            switch self {
            case .text: return AppLocalizer.string("Text")
            case .url: return AppLocalizer.string("URL")
            case .wifi: return AppLocalizer.string("WiFi")
            case .phone: return AppLocalizer.string("Phone")
            }
        }
    }

    @State private var mode: Int
    @State private var generateKind: GenerateKind = .text
    @State private var text = ""
    @State private var scanResult = ""
    @State private var isShowingShareSheet = false
    @State private var shareImage: UIImage?
    @State private var isLocked = false
    @State private var remainingUses = 0
    @State private var didConsumeScanTrial = false
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    private let premiumFeature: PremiumFeature = .qrToolkit

    init(initialMode: Mode = .generate) {
        _mode = State(initialValue: initialMode.rawValue)
    }

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.warning, secondaryTint: AppColor.primary)

            VStack(spacing: 18) {
                if isLocked {
                    FeatureLockedCard(feature: premiumFeature)
                } else {
                    if !purchaseStore.isProUnlocked && remainingUses > 0 {
                        TrialUsageBanner(remainingUses: remainingUses)
                            .padding(.horizontal, 20)
                    }

                    modeSummary

                    Picker("", selection: $mode) {
                        Text(AppLocalizer.string("Generate")).tag(0)
                        Text(AppLocalizer.string("Scan")).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    if mode == 0 {
                        generateView
                    } else {
                        scanView
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .navigationTitle(AppLocalizer.string("QR Toolkit"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshAccessState() }
        .onChange(of: purchaseStore.isProUnlocked) { unlocked in
            if unlocked {
                isLocked = false
                remainingUses = 0
            } else {
                refreshAccessState()
            }
        }
        .onChange(of: scanResult) { value in
            guard !value.isEmpty else { return }
            guard !didConsumeScanTrial else { return }
            guard !purchaseStore.isProUnlocked else { return }
            guard purchaseStore.consumeFreeUseIfNeeded(for: premiumFeature) else {
                refreshAccessState()
                return
            }
            didConsumeScanTrial = true
            refreshAccessState()
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheet(items: shareImage.map { [$0] } ?? [])
        }
    }

    private var modeSummary: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: AppLocalizer.string("Mode"),
                value: mode == 0 ? AppLocalizer.string("Generate") : AppLocalizer.string("Scan"),
                tint: mode == 0 ? AppColor.primary : AppColor.warning
            )
            summaryCard(
                title: AppLocalizer.string("Type"),
                value: mode == 0 ? generateKind.title : AppLocalizer.string("Camera"),
                tint: AppColor.success
            )
        }
        .padding(.horizontal, 20)
    }

    private var generateView: some View {
        ScrollView {
            VStack(spacing: 18) {
                infoCard(
                    title: AppLocalizer.string("Generate a QR code"),
                    detail: AppLocalizer.string("Create a scannable code for links, notes, Wi-Fi, or phone details.")
                )

                VStack(alignment: .leading, spacing: 14) {
                    Picker(AppLocalizer.string("Generate"), selection: $generateKind) {
                        ForEach(GenerateKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField(inputPlaceholder, text: $text)
                        .padding(14)
                        .background(AppColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppColor.border, lineWidth: 1)
                        )

                    Text(generateHint)
                        .appFont(size: 13, weight: .regular)
                        .foregroundColor(AppColor.secondaryText)
                }
                .padding(16)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColor.border, lineWidth: 1)
                )

                VStack(spacing: 14) {
                    if let image = qrImage {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 240, height: 240)
                            .padding(20)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppColor.surface)
                            .frame(width: 240, height: 240)
                            .overlay(
                                Text(AppLocalizer.string("Generated QR code will appear here."))
                                    .appFont(size: 14, weight: .regular)
                                    .foregroundColor(AppColor.secondaryText)
                                    .padding(20)
                            )
                    }

                    HStack(spacing: 12) {
                        Button(AppLocalizer.string("Save")) {
                            guard consumeFeatureUseIfNeeded() else { return }
                            if let qrImage {
                                UIImageWriteToSavedPhotosAlbum(qrImage, nil, nil, nil)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppColor.border, lineWidth: 1)
                        )
                        .disabled(qrImage == nil)

                        Button(AppLocalizer.string("Share")) {
                            guard consumeFeatureUseIfNeeded() else { return }
                            shareImage = qrImage
                            isShowingShareSheet = qrImage != nil
                        }
                        .appFont(size: 16, weight: .bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColor.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .disabled(qrImage == nil)
                    }
                }
                .padding(16)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColor.border, lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private var scanView: some View {
        ScrollView {
            VStack(spacing: 18) {
                infoCard(
                    title: AppLocalizer.string("Scan a QR code"),
                    detail: AppLocalizer.string("Use the camera to read links, Wi-Fi details, or text instantly.")
                )

                QRScannerView(result: $scanResult)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 12) {
                    Text(AppLocalizer.string("Detected Content"))
                        .appFont(size: 18, weight: .bold)
                        .foregroundColor(AppColor.primaryText)

                    Text(scanResult.isEmpty ? AppLocalizer.string("Point the camera at a QR code.") : scanResult)
                        .appFont(size: 16, weight: .medium)
                        .foregroundColor(scanResult.isEmpty ? AppColor.secondaryText : AppColor.primaryText)
                        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                        .padding(14)
                        .background(AppColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    HStack(spacing: 12) {
                        Button(AppLocalizer.string("Copy")) {
                            UIPasteboard.general.string = scanResult
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppColor.border, lineWidth: 1)
                        )
                        .disabled(scanResult.isEmpty)

                        if let url = URL(string: scanResult), scanResult.hasPrefix("http") {
                            Link(destination: url) {
                                Text(AppLocalizer.string("Open"))
                                    .appFont(size: 16, weight: .bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppColor.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                }
                .padding(16)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColor.border, lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
        }
    }

    private var inputPlaceholder: String {
        switch generateKind {
        case .text:
            return AppLocalizer.string("Enter text, URL, WiFi, or phone")
        case .url:
            return "https://"
        case .wifi:
            return "WIFI:T:WPA;S:MyWiFi;P:password;;"
        case .phone:
            return "+1 555 123 4567"
        }
    }

    private var generateHint: String {
        switch generateKind {
        case .text:
            return AppLocalizer.string("Share plain text, notes, or short messages.")
        case .url:
            return AppLocalizer.string("Paste a full website link for instant access.")
        case .wifi:
            return AppLocalizer.string("Use the standard Wi-Fi QR format so devices can join quickly.")
        case .phone:
            return AppLocalizer.string("Add a phone number that opens in the dialer.")
        }
    }

    private func infoCard(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)
            Text(detail)
                .appFont(size: 14, weight: .regular)
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private func summaryCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .appFont(size: 12, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
            Text(value)
                .appFont(size: 16, weight: .bold)
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private var qrImage: UIImage? {
        guard !text.isEmpty else { return nil }
        filter.setValue(Data(text.utf8), forKey: "inputMessage")
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10)), from: outputImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private func refreshAccessState() {
        guard !purchaseStore.isProUnlocked else {
            isLocked = false
            remainingUses = 0
            return
        }
        isLocked = !purchaseStore.hasAccess(to: premiumFeature)
        remainingUses = purchaseStore.remainingFreeUses(for: premiumFeature)
    }

    private func consumeFeatureUseIfNeeded() -> Bool {
        guard !purchaseStore.isProUnlocked else { return true }
        guard purchaseStore.consumeFreeUseIfNeeded(for: premiumFeature) else {
            refreshAccessState()
            return false
        }
        refreshAccessState()
        return true
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct QRScannerView: UIViewControllerRepresentable {
    @Binding var result: String

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCode = { result = $0 }
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

private final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    var onCode: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        let output = AVCaptureMetadataOutput()
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        session.startRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.first?.frame = view.bounds
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let code = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let value = code.stringValue {
            onCode?(value)
        }
    }
}
