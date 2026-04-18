import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins
import UIKit

struct QRCodeToolView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore
    @StateObject private var photoSaver = PhotoLibrarySaver()
    @FocusState private var isInputFocused: Bool
    enum Mode: Int {
        case generate = 0
        case scan = 1
    }

    enum CameraAccessState {
        case checking
        case granted
        case denied
        case unavailable
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

    enum QRColorStyle: String, CaseIterable, Identifiable {
        case classic
        case ocean
        case forest
        case plum
        case sunset

        var id: String { rawValue }

        var title: String {
            switch self {
            case .classic: return AppLocalizer.string("Classic")
            case .ocean: return AppLocalizer.string("Ocean")
            case .forest: return AppLocalizer.string("Forest")
            case .plum: return AppLocalizer.string("Plum")
            case .sunset: return AppLocalizer.string("Sunset")
            }
        }

        var foreground: UIColor {
            switch self {
            case .classic: return UIColor.black
            case .ocean: return UIColor(red: 0.07, green: 0.36, blue: 0.78, alpha: 1)
            case .forest: return UIColor(red: 0.07, green: 0.47, blue: 0.31, alpha: 1)
            case .plum: return UIColor(red: 0.41, green: 0.19, blue: 0.63, alpha: 1)
            case .sunset: return UIColor(red: 0.82, green: 0.34, blue: 0.18, alpha: 1)
            }
        }

        var swatch: Color {
            Color(uiColor: foreground)
        }
    }

    @State private var mode: Int
    @State private var generateKind: GenerateKind = .text
    @State private var colorStyle: QRColorStyle = .classic
    @State private var text = ""
    @State private var scanResult = ""
    @State private var isShowingShareSheet = false
    @State private var shareImage: UIImage?
    @State private var saveMessage = ""
    @State private var saveMessageTint = AppColor.success
    @State private var saveAlertTitle = ""
    @State private var saveAlertMessage = ""
    @State private var isShowingSaveAlert = false
    @State private var isLocked = false
    @State private var remainingUses = 0
    @State private var didConsumeGenerateTrial = false
    @State private var didConsumeScanTrial = false
    @State private var cameraAccessState: CameraAccessState = .checking
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
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
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
            AppFeedback.success()
            saveMessage = ""
            guard !didConsumeScanTrial else { return }
            guard !purchaseStore.isProUnlocked else { return }
            guard purchaseStore.consumeFreeUseIfNeeded(for: premiumFeature) else {
                refreshAccessState()
                return
            }
            didConsumeScanTrial = true
            refreshAccessState()
        }
        .onChange(of: mode) { _ in
            saveMessage = ""
        }
        .onChange(of: text) { _ in
            saveMessage = ""
            didConsumeGenerateTrial = false
        }
        .onChange(of: generateKind) { _ in
            saveMessage = ""
            didConsumeGenerateTrial = false
        }
        .alert(saveAlertTitle, isPresented: $isShowingSaveAlert) {
            Button(AppLocalizer.string("OK"), role: .cancel) {}
        } message: {
            Text(saveAlertMessage)
        }
        .background(
            ShareSheetPresenter(
                isPresented: $isShowingShareSheet,
                items: shareImage.map { [$0] } ?? []
            )
        )
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
                        .focused($isInputFocused)
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

                    colorPickerRow
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
                            guard consumeGenerateUseIfNeeded() else { return }
                            if let qrImage {
                                photoSaver.save(qrImage) { result in
                                    switch result {
                                    case .success:
                                        AppFeedback.success()
                                        saveMessage = AppLocalizer.string("Saved to Photos.")
                                        saveMessageTint = AppColor.success
                                        saveAlertTitle = AppLocalizer.string("Save Complete")
                                        saveAlertMessage = AppLocalizer.string("Saved to Photos. Open the Photos app to view it.")
                                    case .failure:
                                        saveMessage = saveFailureMessage(for: result)
                                        saveMessageTint = AppColor.warning
                                        saveAlertTitle = AppLocalizer.string("Save Failed")
                                        saveAlertMessage = saveFailureMessage(for: result)
                                    }
                                    isShowingSaveAlert = true
                                }
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
                            guard consumeGenerateUseIfNeeded() else { return }
                            AppFeedback.action()
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

                    if !saveMessage.isEmpty {
                        Text(saveMessage)
                            .appFont(size: 13, weight: .medium)
                            .foregroundColor(saveMessageTint)
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
        .scrollDismissesKeyboardCompat()
    }

    private var scanView: some View {
        ScrollView {
            VStack(spacing: 18) {
                infoCard(
                    title: AppLocalizer.string("Scan a QR code"),
                    detail: AppLocalizer.string("Use the camera to read links, Wi-Fi details, or text instantly.")
                )

                if cameraAccessState == .granted || cameraAccessState == .checking {
                    QRScannerView(result: $scanResult, accessState: $cameraAccessState)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppColor.border, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                } else {
                    cameraAccessCard
                        .padding(.horizontal, 20)
                }

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
                            AppFeedback.success()
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
                            Button {
                                AppFeedback.action()
                                UIApplication.shared.open(url)
                            } label: {
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

    private var cameraAccessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalizer.string("Camera access is needed to scan codes."))
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(AppLocalizer.string("Allow camera access in Settings, then come back to scan QR codes instantly."))
                .appFont(size: 14, weight: .regular)
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button(AppLocalizer.string("Open Settings")) {
                AppFeedback.action()
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .appFont(size: 15, weight: .bold)
            .foregroundColor(AppColor.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
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

    private func saveFailureMessage(for result: Result<Void, Error>) -> String {
        guard case let .failure(error) = result else {
            return AppLocalizer.string("Could not save right now.")
        }

        if let photoError = error as? PhotoLibrarySaveError {
            switch photoError {
            case .permissionDenied:
                return AppLocalizer.string("Please allow Photos access in Settings to save images.")
            case .restricted:
                return AppLocalizer.string("Photos access is restricted on this device.")
            case .unknown:
                return AppLocalizer.string("Could not save right now.")
            }
        }

        return AppLocalizer.string("Could not save right now.")
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

    private var colorPickerRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalizer.string("Color"))
                .appFont(size: 14, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            HStack(spacing: 10) {
                ForEach(QRColorStyle.allCases) { style in
                    Button {
                        AppFeedback.selection()
                        colorStyle = style
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(style.swatch)
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                                        .padding(3)
                                        .opacity(colorStyle == style ? 1 : 0)
                                )
                            Text(style.title)
                                .appFont(size: 11, weight: .medium)
                                .foregroundColor(colorStyle == style ? AppColor.primaryText : AppColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(colorStyle == style ? style.swatch.opacity(0.9) : AppColor.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var qrImage: UIImage? {
        guard let payload = qrPayload else { return nil }
        filter.setValue(Data(payload.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage else {
            return nil
        }

        let falseColorFilter = CIFilter.falseColor()
        falseColorFilter.inputImage = outputImage
        falseColorFilter.color0 = CIColor(color: colorStyle.foreground)
        falseColorFilter.color1 = CIColor(color: .white)

        guard let coloredImage = falseColorFilter.outputImage else {
            return nil
        }

        let scaledImage = coloredImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent.integral) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private var qrPayload: String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        switch generateKind {
        case .text:
            return trimmed
        case .url:
            if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
                return trimmed
            }
            return "https://\(trimmed)"
        case .wifi:
            return trimmed.hasPrefix("WIFI:") ? trimmed : "WIFI:T:WPA;S:\(trimmed);P:;;"
        case .phone:
            let digits = trimmed.filter { !$0.isWhitespace }
            return digits.lowercased().hasPrefix("tel:") ? digits : "tel:\(digits)"
        }
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

    private func dismissKeyboard() {
        isInputFocused = false
    }

    private func consumeGenerateUseIfNeeded() -> Bool {
        guard !didConsumeGenerateTrial else { return true }
        guard consumeFeatureUseIfNeeded() else { return false }
        didConsumeGenerateTrial = true
        return true
    }
}

private extension View {
    @ViewBuilder
    func scrollDismissesKeyboardCompat() -> some View {
        if #available(iOS 16.0, *) {
            scrollDismissesKeyboard(.immediately)
        } else {
            self
        }
    }
}

private struct ShareSheetPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let items: [Any]

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented, uiViewController.presentedViewController == nil, !items.isEmpty else { return }

        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
        }

        if let popover = controller.popoverPresentationController {
            popover.sourceView = uiViewController.view
            popover.sourceRect = CGRect(
                x: uiViewController.view.bounds.midX,
                y: uiViewController.view.bounds.maxY - 1,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = []
        }

        DispatchQueue.main.async {
            uiViewController.present(controller, animated: true)
        }
    }
}

private struct QRScannerView: UIViewControllerRepresentable {
    @Binding var result: String
    @Binding var accessState: QRCodeToolView.CameraAccessState

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onAccessState = { accessState = $0 }
        controller.onCode = { scannedValue in
            guard result != scannedValue else { return }
            result = scannedValue
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

private final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    var onCode: ((String) -> Void)?
    var onAccessState: ((QRCodeToolView.CameraAccessState) -> Void)?
    private var lastScannedValue = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureCamera()
    }

    private func configureCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    granted ? self.setupSession() : self.onAccessState?(.denied)
                }
            }
        case .denied, .restricted:
            onAccessState?(.denied)
        @unknown default:
            onAccessState?(.unavailable)
        }
    }

    private func setupSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            onAccessState?(.unavailable)
            return
        }
        let output = AVCaptureMetadataOutput()
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        onAccessState?(.granted)
        session.startRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.first?.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !session.isRunning {
            session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let code = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let value = code.stringValue,
           value != lastScannedValue {
            lastScannedValue = value
            onCode?(value)
        }
    }
}
