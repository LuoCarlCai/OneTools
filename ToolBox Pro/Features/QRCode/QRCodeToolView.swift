import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins
import PhotosUI
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

    enum QRBackgroundStyle: String, CaseIterable, Identifiable {
        case white
        case cream
        case mist
        case midnight

        var id: String { rawValue }

        var title: String {
            switch self {
            case .white: return AppLocalizer.string("White")
            case .cream: return AppLocalizer.string("Cream")
            case .mist: return AppLocalizer.string("Mist")
            case .midnight: return AppLocalizer.string("Midnight")
            }
        }

        var background: UIColor {
            switch self {
            case .white: return .white
            case .cream: return UIColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 1)
            case .mist: return UIColor(red: 0.92, green: 0.96, blue: 0.99, alpha: 1)
            case .midnight: return UIColor(red: 0.12, green: 0.16, blue: 0.24, alpha: 1)
            }
        }

        var swatch: Color {
            Color(uiColor: background)
        }
    }

    enum QRExportSize: String, CaseIterable, Identifiable {
        case compact
        case standard
        case large

        var id: String { rawValue }

        var title: String {
            switch self {
            case .compact: return AppLocalizer.string("Compact")
            case .standard: return AppLocalizer.string("Standard")
            case .large: return AppLocalizer.string("Large")
            }
        }

        var dimension: CGFloat {
            switch self {
            case .compact: return 768
            case .standard: return 1536
            case .large: return 2048
            }
        }
    }

    enum QRModuleStyle: String, CaseIterable, Identifiable {
        case sharp
        case rounded
        case dots

        var id: String { rawValue }

        var title: String {
            switch self {
            case .sharp: return AppLocalizer.string("Sharp")
            case .rounded: return AppLocalizer.string("Rounded")
            case .dots: return AppLocalizer.string("Dots")
            }
        }
    }

    enum QRPaddingStyle: String, CaseIterable, Identifiable {
        case tight
        case balanced
        case roomy

        var id: String { rawValue }

        var title: String {
            switch self {
            case .tight: return AppLocalizer.string("Tight")
            case .balanced: return AppLocalizer.string("Balanced")
            case .roomy: return AppLocalizer.string("Roomy")
            }
        }

        var insetRatio: CGFloat {
            switch self {
            case .tight: return 0.08
            case .balanced: return 0.13
            case .roomy: return 0.18
            }
        }
    }

    enum QRBorderStyle: String, CaseIterable, Identifiable {
        case none
        case outline
        case card

        var id: String { rawValue }

        var title: String {
            switch self {
            case .none: return AppLocalizer.string("None")
            case .outline: return AppLocalizer.string("Outline")
            case .card: return AppLocalizer.string("Card")
            }
        }
    }

    @State private var mode: Int
    @State private var generateKind: GenerateKind = .text
    @State private var colorStyle: QRColorStyle = .classic
    @State private var backgroundStyle: QRBackgroundStyle = .white
    @State private var moduleStyle: QRModuleStyle = .sharp
    @State private var paddingStyle: QRPaddingStyle = .balanced
    @State private var borderStyle: QRBorderStyle = .none
    @State private var exportSize: QRExportSize = .standard
    @State private var text = ""
    @State private var logoImage: UIImage?
    @State private var scanResult = ""
    @State private var isShowingShareSheet = false
    @State private var isShowingLogoPicker = false
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
        .sheet(isPresented: $isShowingLogoPicker) {
            QRLogoPicker(image: $logoImage)
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
                    backgroundPickerRow
                    moduleStylePickerRow
                    paddingPickerRow
                    borderPickerRow
                    logoPickerRow
                    exportSizePickerRow
                }
                .padding(16)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColor.border, lineWidth: 1)
                )

                VStack(spacing: 14) {
                    if let image = qrPreviewImage {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 280, height: 280)
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
                            if let exportImage {
                                photoSaver.save(exportImage) { result in
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
                        .disabled(exportImage == nil)

                        Button(AppLocalizer.string("Share")) {
                            guard consumeGenerateUseIfNeeded() else { return }
                            AppFeedback.action()
                            shareImage = exportImage
                            isShowingShareSheet = exportImage != nil
                        }
                        .appFont(size: 16, weight: .bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColor.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .disabled(exportImage == nil)
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

    private var backgroundPickerRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalizer.string("Background"))
                .appFont(size: 14, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            HStack(spacing: 10) {
                ForEach(QRBackgroundStyle.allCases) { style in
                    Button {
                        AppFeedback.selection()
                        backgroundStyle = style
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(style.swatch)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(style == .white ? AppColor.border : Color.white.opacity(0.8), lineWidth: 1.5)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(backgroundStyle == style ? AppColor.primary : .clear, lineWidth: 2.5)
                                        .padding(-4)
                                )
                            Text(style.title)
                                .appFont(size: 11, weight: .medium)
                                .foregroundColor(backgroundStyle == style ? AppColor.primaryText : AppColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(backgroundStyle == style ? style.swatch.opacity(0.95) : AppColor.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var logoPickerRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalizer.string("Logo"))
                .appFont(size: 14, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(AppLocalizer.string("Add a centered logo for a branded QR code."))
                .appFont(size: 13, weight: .regular)
                .foregroundColor(AppColor.secondaryText)

            HStack(spacing: 12) {
                Button {
                    AppFeedback.selection()
                    isShowingLogoPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "photo")
                            .font(.system(size: 15, weight: .semibold))
                        Text(logoImage == nil ? AppLocalizer.string("Add Logo") : AppLocalizer.string("Change"))
                            .appFont(size: 14, weight: .bold)
                    }
                    .foregroundColor(AppColor.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if let logoImage {
                    HStack(spacing: 10) {
                        Image(uiImage: logoImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Button(AppLocalizer.string("Remove")) {
                            AppFeedback.selection()
                            self.logoImage = nil
                        }
                        .appFont(size: 13, weight: .bold)
                        .foregroundColor(AppColor.warning)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var moduleStylePickerRow: some View {
        optionRow(
            title: AppLocalizer.string("Module Style"),
            options: QRModuleStyle.allCases,
            selected: moduleStyle,
            selectionTitle: \.title
        ) { style in
            moduleStyle = style
        }
    }

    private var paddingPickerRow: some View {
        optionRow(
            title: AppLocalizer.string("Padding"),
            options: QRPaddingStyle.allCases,
            selected: paddingStyle,
            selectionTitle: \.title
        ) { style in
            paddingStyle = style
        }
    }

    private var borderPickerRow: some View {
        optionRow(
            title: AppLocalizer.string("Border"),
            options: QRBorderStyle.allCases,
            selected: borderStyle,
            selectionTitle: \.title
        ) { style in
            borderStyle = style
        }
    }

    private var exportSizePickerRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalizer.string("Export Size"))
                .appFont(size: 14, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(AppLocalizer.string("Save and share the QR image at a higher resolution."))
                .appFont(size: 13, weight: .regular)
                .foregroundColor(AppColor.secondaryText)

            HStack(spacing: 10) {
                ForEach(QRExportSize.allCases) { size in
                    Button {
                        AppFeedback.selection()
                        exportSize = size
                    } label: {
                        Text(size.title)
                            .appFont(size: 13, weight: .bold)
                            .foregroundColor(exportSize == size ? AppColor.primaryText : AppColor.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(exportSize == size ? AppColor.primary : AppColor.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var qrPreviewImage: UIImage? {
        renderedQRCodeImage(dimension: 1200)
    }

    private var exportImage: UIImage? {
        renderedQRCodeImage(dimension: exportSize.dimension)
    }

    private var qrMatrix: (modules: [Bool], side: Int)? {
        guard let payload = qrPayload else { return nil }
        filter.setValue(Data(payload.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage else {
            return nil
        }

        let extent = outputImage.extent.integral
        guard let cgImage = context.createCGImage(outputImage, from: extent),
              let data = cgImage.dataProvider?.data,
              let bytePointer = CFDataGetBytePtr(data) else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = max(1, cgImage.bitsPerPixel / 8)
        let bytesPerRow = cgImage.bytesPerRow
        var modules: [Bool] = []
        modules.reserveCapacity(width * height)

        for row in 0..<height {
            for column in 0..<width {
                let offset = row * bytesPerRow + column * bytesPerPixel
                let isDark: Bool
                if bytesPerPixel >= 3 {
                    let red = Int(bytePointer[offset])
                    let green = Int(bytePointer[offset + 1])
                    let blue = Int(bytePointer[offset + 2])
                    isDark = red + green + blue < 382
                } else {
                    isDark = bytePointer[offset] < 128
                }
                modules.append(isDark)
            }
        }

        guard width == height else {
            return nil
        }

        return (modules, width)
    }

    private func renderedQRCodeImage(dimension: CGFloat) -> UIImage? {
        guard let qrMatrix else {
            return nil
        }

        let canvasSize = CGSize(width: dimension, height: dimension)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: canvasSize, format: format).image { rendererContext in
            let context = rendererContext.cgContext
            let canvasRect = CGRect(origin: .zero, size: canvasSize)
            let frameRect = decoratedFrameRect(in: canvasRect)
            let qrRect = qrDrawingRect(in: frameRect)

            context.setFillColor(backgroundStyle.background.cgColor)
            context.fill(canvasRect)
            drawBorder(in: frameRect, canvasRect: canvasRect, context: context)
            drawModules(qrMatrix, in: qrRect, context: context)

            if let logoImage {
                drawLogo(logoImage, in: qrRect, context: context)
            }
        }
    }

    private func decoratedFrameRect(in canvasRect: CGRect) -> CGRect {
        switch borderStyle {
        case .none:
            return canvasRect
        case .outline:
            return canvasRect.insetBy(dx: canvasRect.width * 0.035, dy: canvasRect.height * 0.035)
        case .card:
            return canvasRect.insetBy(dx: canvasRect.width * 0.055, dy: canvasRect.height * 0.055)
        }
    }

    private func qrDrawingRect(in frameRect: CGRect) -> CGRect {
        let inset = frameRect.width * paddingStyle.insetRatio
        return frameRect.insetBy(dx: inset, dy: inset)
    }

    private func drawBorder(in frameRect: CGRect, canvasRect: CGRect, context: CGContext) {
        guard borderStyle != .none else { return }

        let cornerRadius = frameRect.width * 0.12
        let path = UIBezierPath(roundedRect: frameRect, cornerRadius: cornerRadius)

        if borderStyle == .card {
            let fillColor: UIColor
            if backgroundStyle == .midnight {
                fillColor = UIColor.white.withAlphaComponent(0.09)
            } else {
                fillColor = UIColor.black.withAlphaComponent(0.035)
            }
            context.setFillColor(fillColor.cgColor)
            context.addPath(path.cgPath)
            context.drawPath(using: .fill)
        }

        let strokeColor = colorStyle.foreground.withAlphaComponent(borderStyle == .outline ? 0.18 : 0.12)
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(canvasRect.width * 0.012)
        context.addPath(path.cgPath)
        context.strokePath()
    }

    private func drawModules(_ matrix: (modules: [Bool], side: Int), in rect: CGRect, context: CGContext) {
        let moduleSize = rect.width / CGFloat(matrix.side)
        let fillColor = colorStyle.foreground.cgColor
        context.setFillColor(fillColor)

        for row in 0..<matrix.side {
            for column in 0..<matrix.side {
                let index = row * matrix.side + column
                guard matrix.modules[index] else { continue }

                let moduleRect = CGRect(
                    x: rect.minX + CGFloat(column) * moduleSize,
                    y: rect.minY + CGFloat(row) * moduleSize,
                    width: moduleSize,
                    height: moduleSize
                )

                let protectedModule = isFinderModule(row: row, column: column, side: matrix.side)
                drawModule(in: moduleRect, protectedModule: protectedModule, context: context)
            }
        }
    }

    private func drawModule(in rect: CGRect, protectedModule: Bool, context: CGContext) {
        let appliedStyle: QRModuleStyle = protectedModule && moduleStyle == .dots ? .rounded : moduleStyle

        switch appliedStyle {
        case .sharp:
            context.fill(rect)
        case .rounded:
            let inset = rect.width * 0.06
            let drawRect = rect.insetBy(dx: inset, dy: inset)
            let path = UIBezierPath(roundedRect: drawRect, cornerRadius: drawRect.width * 0.28)
            context.addPath(path.cgPath)
            context.drawPath(using: .fill)
        case .dots:
            let inset = rect.width * 0.18
            let drawRect = rect.insetBy(dx: inset, dy: inset)
            context.fillEllipse(in: drawRect)
        }
    }

    private func isFinderModule(row: Int, column: Int, side: Int) -> Bool {
        let area = 8
        let top = row < area
        let bottom = row >= side - area
        let left = column < area
        let right = column >= side - area
        return (top && left) || (top && right) || (bottom && left)
    }

    private func drawLogo(_ image: UIImage, in qrRect: CGRect, context: CGContext) {
        let cardSide = qrRect.width * 0.26
        let imageSide = cardSide * 0.66
        let cardRect = CGRect(
            x: qrRect.midX - (cardSide / 2),
            y: qrRect.midY - (cardSide / 2),
            width: cardSide,
            height: cardSide
        )

        context.setFillColor(UIColor.white.cgColor)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cardSide * 0.24)
        context.addPath(cardPath.cgPath)
        context.drawPath(using: .fill)

        let imageRect = CGRect(
            x: qrRect.midX - (imageSide / 2),
            y: qrRect.midY - (imageSide / 2),
            width: imageSide,
            height: imageSide
        )
        let imagePath = UIBezierPath(roundedRect: imageRect, cornerRadius: imageSide * 0.24)
        context.saveGState()
        context.addPath(imagePath.cgPath)
        context.clip()
        image.draw(in: imageRect)
        context.restoreGState()
    }

    private func optionRow<Option: Identifiable & Equatable>(
        title: String,
        options: [Option],
        selected: Option,
        selectionTitle: KeyPath<Option, String>,
        onSelect: @escaping (Option) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .appFont(size: 14, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            HStack(spacing: 10) {
                ForEach(options) { option in
                    Button {
                        AppFeedback.selection()
                        onSelect(option)
                    } label: {
                        Text(option[keyPath: selectionTitle])
                            .appFont(size: 13, weight: .bold)
                            .foregroundColor(selected == option ? AppColor.primaryText : AppColor.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selected == option ? AppColor.primary : AppColor.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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

private struct QRLogoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: QRLogoPicker

        init(_ parent: QRLogoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let result = results.first else { return }
            guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }

            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage else { return }
                DispatchQueue.main.async {
                    self.parent.image = image
                }
            }
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
