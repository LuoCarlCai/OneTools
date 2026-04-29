import SwiftUI
import PhotosUI
import Photos
import UIKit

struct WatermarkView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore
    @StateObject private var photoSaver = PhotoLibrarySaver()
    enum WatermarkFontStyle: String, CaseIterable, Identifiable {
        case system
        case rounded
        case serif
        case monospaced

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: return AppLocalizer.string("System")
            case .rounded: return AppLocalizer.string("Rounded")
            case .serif: return AppLocalizer.string("Serif")
            case .monospaced: return AppLocalizer.string("Monospace")
            }
        }

        func swiftUIFont(size: CGFloat) -> Font {
            switch self {
            case .system:
                return .system(size: size, weight: .bold)
            case .rounded:
                return .system(size: size, weight: .bold, design: .rounded)
            case .serif:
                return .system(size: size, weight: .bold, design: .serif)
            case .monospaced:
                return .system(size: size, weight: .bold, design: .monospaced)
            }
        }

        func uiFont(size: CGFloat) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: .bold)
            let descriptor = base.fontDescriptor

            let design: UIFontDescriptor.SystemDesign?
            switch self {
            case .system:
                design = nil
            case .rounded:
                design = .rounded
            case .serif:
                design = .serif
            case .monospaced:
                design = .monospaced
            }

            guard let design,
                  let styledDescriptor = descriptor.withDesign(design) else {
                return base
            }
            return UIFont(descriptor: styledDescriptor, size: size)
        }
    }

    enum WatermarkColorStyle: String, CaseIterable, Identifiable {
        case white
        case ocean
        case forest
        case plum
        case sunset

        var id: String { rawValue }

        var title: String {
            switch self {
            case .white: return AppLocalizer.string("White")
            case .ocean: return AppLocalizer.string("Ocean")
            case .forest: return AppLocalizer.string("Forest")
            case .plum: return AppLocalizer.string("Plum")
            case .sunset: return AppLocalizer.string("Sunset")
            }
        }

        var color: Color {
            Color(uiColor: uiColor)
        }

        var uiColor: UIColor {
            switch self {
            case .white: return .white
            case .ocean: return UIColor(red: 0.09, green: 0.47, blue: 0.90, alpha: 1)
            case .forest: return UIColor(red: 0.14, green: 0.58, blue: 0.34, alpha: 1)
            case .plum: return UIColor(red: 0.50, green: 0.26, blue: 0.68, alpha: 1)
            case .sunset: return UIColor(red: 0.90, green: 0.45, blue: 0.22, alpha: 1)
            }
        }
    }

    enum WatermarkLayoutStyle: String, CaseIterable, Identifiable {
        case floating
        case tiled
        case footer

        var id: String { rawValue }

        var title: String {
            switch self {
            case .floating: return AppLocalizer.string("Floating")
            case .tiled: return AppLocalizer.string("Tiled")
            case .footer: return AppLocalizer.string("Footer")
            }
        }
    }

    @State private var selectedImage: UIImage?
    @State private var isShowingPicker = false
    @State private var watermarkText = "One Tools"
    @State private var layoutStyle: WatermarkLayoutStyle = .floating
    @State private var fontStyle: WatermarkFontStyle = .rounded
    @State private var colorStyle: WatermarkColorStyle = .white
    @State private var textSize = 34.0
    @State private var watermarkScale = 1.0
    @State private var opacity = 0.55
    @State private var outlineWidth = 0.0
    @State private var shadowRadius = 2.0
    @State private var rotation = -18.0
    @State private var horizontalPosition = 0.5
    @State private var verticalPosition = 0.5
    @State private var isLocked = false
    @State private var remainingUses = 0
    @State private var saveMessage = ""
    @State private var saveMessageTint = AppColor.success
    @State private var isSaving = false
    @State private var saveAlertTitle = ""
    @State private var saveAlertMessage = ""
    @State private var isShowingSaveAlert = false
    @State private var didConsumeTrialInSession = false
    @GestureState private var gestureScale: CGFloat = 1
    @GestureState private var gestureRotation: Angle = .zero
    @GestureState private var gestureTranslation: CGSize = .zero
    private let premiumFeature: PremiumFeature = .watermark

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: Color(hex: 0x8B5CF6), secondaryTint: AppColor.primary)

            ScrollView {
                VStack(spacing: 18) {
                    if isLocked {
                        FeatureLockedCard(feature: premiumFeature)
                    } else {
                        if !purchaseStore.isProUnlocked && remainingUses > 0 {
                            TrialUsageBanner(remainingUses: remainingUses)
                        }

                        introCard
                        preview
                        watermarkSummary
                        editor
                        saveButton
                        saveStatus
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Watermark"))
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
        .onChange(of: selectedImage) { _ in
            saveMessage = ""
            didConsumeTrialInSession = false
            resetWatermarkPlacement()
        }
        .alert(saveAlertTitle, isPresented: $isShowingSaveAlert) {
            Button(AppLocalizer.string("OK"), role: .cancel) {}
        } message: {
            Text(saveAlertMessage)
        }
        .sheet(isPresented: $isShowingPicker) {
            LegacyImagePicker(image: $selectedImage)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLocalizer.string("Protect and label your images"))
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)
            Text(AppLocalizer.string("Add a text watermark, fine-tune its style, and save a fresh copy for sharing."))
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
    }

    private var watermarkSummary: some View {
        HStack(spacing: 12) {
            summaryPill(title: AppLocalizer.string("Layout"), value: layoutStyle.title)
            summaryPill(title: AppLocalizer.string("Opacity"), value: "\(Int((safeOpacity * 100).rounded()))%")
            summaryPill(title: AppLocalizer.string("Angle"), value: "\(Int(safeRotation.rounded()))°")
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(AppLocalizer.string("Image Preview"))
                    .appFont(size: 18, weight: .bold)
                Spacer()
                Button {
                    AppFeedback.selection()
                    isShowingPicker = true
                } label: {
                    Text(selectedImage == nil ? AppLocalizer.string("Choose") : AppLocalizer.string("Change"))
                        .foregroundColor(AppColor.primary)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppColor.background)
                if let image = selectedImage {
                    GeometryReader { proxy in
                        let imageFrame = fittedImageFrame(for: image.size, in: proxy.size)

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .overlay(alignment: .topLeading) {
                                watermarkContent(in: imageFrame.size)
                                    .frame(width: imageFrame.size.width, height: imageFrame.size.height)
                                    .offset(x: imageFrame.origin.x, y: imageFrame.origin.y)
                            }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(AppColor.primary)

                        Text(AppLocalizer.string("Choose a photo to start"))
                            .appFont(size: 16, weight: .bold)
                            .foregroundColor(AppColor.primaryText)

                        Text(AppLocalizer.string("Add a clean watermark before saving a new copy."))
                            .appFont(size: 14, weight: .regular)
                            .foregroundColor(AppColor.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColor.border, lineWidth: 1)
            )
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalizer.string("Watermark Text"))
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            TextField(AppLocalizer.string("Enter watermark text"), text: $watermarkText)
                .padding(14)
                .background(AppColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColor.border, lineWidth: 1)
                )

            layoutPickerRow
            fontPickerRow
            colorPickerRow

            SliderRow(title: AppLocalizer.string("Opacity"), value: $opacity, range: 0.15...1.0)
            SliderRow(title: AppLocalizer.string("Base Size"), value: $textSize, range: 16...82)
            SliderRow(title: AppLocalizer.string("Outline"), value: $outlineWidth, range: 0...8)
            SliderRow(title: AppLocalizer.string("Shadow"), value: $shadowRadius, range: 0...12)

            Button(AppLocalizer.string("Reset Placement")) {
                AppFeedback.selection()
                resetWatermarkPlacement()
            }
            .buttonStyle(WatermarkSecondaryButtonStyle(color: AppColor.primary))

            Text(layoutHint)
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
    }

    private var saveButton: some View {
        Text(isSaving ? AppLocalizer.string("Saving to Photos...") : AppLocalizer.string("Save"))
            .appFont(size: 16, weight: .bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(selectedImage == nil || isSaving ? AppColor.secondaryText : AppColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture {
                performSave()
            }
            .zIndex(5)
    }

    private var saveStatus: some View {
        Group {
            if !saveMessage.isEmpty {
                Text(saveMessage)
                    .appFont(size: 13, weight: .medium)
                    .foregroundColor(saveMessageTint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func watermarkContent(in size: CGSize) -> some View {
        Group {
            switch layoutStyle {
            case .floating:
                watermarkTextLayer
                    .rotationEffect(currentRotation)
                    .position(currentWatermarkPosition(in: size))
                    .contentShape(Rectangle())
                    .gesture(dragGesture(in: size))
                    .simultaneousGesture(magnificationGesture)
                    .simultaneousGesture(rotationGesture)
            case .tiled:
                tiledWatermark(in: size)
                    .contentShape(Rectangle())
                    .simultaneousGesture(magnificationGesture)
                    .simultaneousGesture(rotationGesture)
            case .footer:
                footerWatermark(in: size)
                    .contentShape(Rectangle())
                    .simultaneousGesture(magnificationGesture)
            }
        }
    }

    private func tiledWatermark(in size: CGSize) -> some View {
        ZStack {
            ForEach(Array(tiledPositions(in: size).enumerated()), id: \.offset) { _, point in
                watermarkTextLayer
                    .rotationEffect(currentRotation)
                    .position(point)
            }
        }
    }

    private func footerWatermark(in size: CGSize) -> some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.22))
                .frame(height: footerBarHeight)

            watermarkTextLayer
                .scaleEffect(0.9)
                .padding(.bottom, 14)
        }
    }

    private var footerBarHeight: CGFloat {
        max(56, currentWatermarkFontSize * 2.1)
    }

    private func renderedImage() -> UIImage? {
        guard let image = selectedImage else { return nil }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            switch layoutStyle {
            case .floating:
                drawFloatingWatermark(in: ctx.cgContext, canvasSize: image.size)
            case .tiled:
                drawTiledWatermark(in: ctx.cgContext, canvasSize: image.size)
            case .footer:
                drawFooterWatermark(in: ctx.cgContext, canvasSize: image.size)
            }
        }
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .appFont(size: 12, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
            Text(value)
                .appFont(size: 16, weight: .bold)
                .foregroundColor(AppColor.primaryText)
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

    private var watermarkTextLayer: some View {
        ZStack {
            if safeOutlineWidth > 0 {
                ForEach(Array(outlineOffsets.enumerated()), id: \.offset) { _, offset in
                    watermarkBaseText
                        .foregroundColor(Color.black.opacity(min(0.9, safeOpacity + 0.15)))
                        .offset(offset)
                }
            }

            watermarkBaseText
                .foregroundColor(colorStyle.color.opacity(safeOpacity))
                .shadow(
                    color: Color.black.opacity(safeShadowRadius > 0 ? 0.35 : 0),
                    radius: safeShadowRadius,
                    x: 0,
                    y: safeShadowRadius * 0.35
                )
        }
    }

    private var layoutPickerRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(AppLocalizer.string("Layout"))
                    .appFont(size: 15, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                Spacer()
                Text(layoutStyle.title)
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(AppColor.secondaryText)
            }

            HStack(spacing: 8) {
                ForEach(WatermarkLayoutStyle.allCases) { style in
                    Button {
                        AppFeedback.selection()
                        layoutStyle = style
                    } label: {
                        Text(style.title)
                            .appFont(size: 13, weight: .bold)
                            .foregroundColor(layoutStyle == style ? .white : AppColor.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(layoutStyle == style ? AppColor.primary : AppColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(layoutStyle == style ? AppColor.primary : AppColor.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var watermarkBaseText: some View {
        Text(watermarkText)
            .font(fontStyle.swiftUIFont(size: currentWatermarkFontSize))
            .fontWeight(.bold)
    }

    private var outlineOffsets: [CGSize] {
        let distance = max(1, safeOutlineWidth * 0.85)
        return [
            CGSize(width: -distance, height: 0),
            CGSize(width: distance, height: 0),
            CGSize(width: 0, height: -distance),
            CGSize(width: 0, height: distance),
            CGSize(width: -distance, height: -distance),
            CGSize(width: distance, height: -distance),
            CGSize(width: -distance, height: distance),
            CGSize(width: distance, height: distance)
        ]
    }

    private var fontPickerRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(AppLocalizer.string("Font"))
                    .appFont(size: 15, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                Spacer()
                Text(fontStyle.title)
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(AppColor.secondaryText)
            }

            HStack(spacing: 8) {
                ForEach(WatermarkFontStyle.allCases) { style in
                    Button {
                        AppFeedback.selection()
                        fontStyle = style
                    } label: {
                        Text(style.title)
                            .font(style.swiftUIFont(size: 13))
                            .foregroundColor(fontStyle == style ? .white : AppColor.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(fontStyle == style ? AppColor.primary : AppColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(fontStyle == style ? AppColor.primary : AppColor.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var colorPickerRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(AppLocalizer.string("Color"))
                    .appFont(size: 15, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                Spacer()
                Text(colorStyle.title)
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(AppColor.secondaryText)
            }

            HStack(spacing: 10) {
                ForEach(WatermarkColorStyle.allCases) { style in
                    Button {
                        AppFeedback.selection()
                        colorStyle = style
                    } label: {
                        Circle()
                            .fill(style.color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(style == .white ? AppColor.border : .white.opacity(0.75), lineWidth: 1.5)
                            )
                            .overlay(
                                Circle()
                                    .stroke(style == colorStyle ? AppColor.primary : .clear, lineWidth: 2.5)
                                    .padding(-4)
                            )
                            .shadow(color: Color.black.opacity(style == colorStyle ? 0.14 : 0.06), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(style.title)
                }
            }
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

    private func consumeFeatureUseInSessionIfNeeded() -> Bool {
        guard !didConsumeTrialInSession else { return true }
        guard consumeFeatureUseIfNeeded() else { return false }
        didConsumeTrialInSession = true
        return true
    }

    private var currentWatermarkFontSize: Double {
        safeTextSize * min(max(safeGestureScale * safeWatermarkScale, 0.6), 4.0)
    }

    private var currentRotation: Angle {
        Angle(degrees: safeRotation) + safeGestureRotation
    }

    private var safeOpacity: Double {
        opacity.isFinite ? min(max(opacity, 0.15), 1.0) : 0.55
    }

    private var safeOutlineWidth: Double {
        outlineWidth.isFinite ? min(max(outlineWidth, 0), 8) : 0
    }

    private var safeShadowRadius: Double {
        shadowRadius.isFinite ? min(max(shadowRadius, 0), 12) : 2
    }

    private var safeTextSize: Double {
        textSize.isFinite ? min(max(textSize, 16), 82) : 34
    }

    private var safeWatermarkScale: Double {
        watermarkScale.isFinite ? min(max(watermarkScale, 0.6), 4.0) : 1
    }

    private var safeRotation: Double {
        rotation.isFinite ? rotation : -18
    }

    private var safeHorizontalPosition: Double {
        horizontalPosition.isFinite ? min(max(horizontalPosition, 0), 1) : 0.5
    }

    private var safeVerticalPosition: Double {
        verticalPosition.isFinite ? min(max(verticalPosition, 0), 1) : 0.5
    }

    private var safeGestureScale: Double {
        gestureScale.isFinite ? Double(gestureScale) : 1
    }

    private var safeGestureRotation: Angle {
        let degrees = gestureRotation.degrees
        return degrees.isFinite ? gestureRotation : .zero
    }

    private var safeGestureTranslation: CGSize {
        CGSize(
            width: gestureTranslation.width.isFinite ? gestureTranslation.width : 0,
            height: gestureTranslation.height.isFinite ? gestureTranslation.height : 0
        )
    }

    private var layoutHint: String {
        switch layoutStyle {
        case .floating:
            return AppLocalizer.string("Drag the watermark to move it. Pinch to resize and rotate with two fingers directly on the preview.")
        case .tiled:
            return AppLocalizer.string("Repeat the watermark across the image. Pinch to resize and rotate the pattern.")
        case .footer:
            return AppLocalizer.string("Use a clean signature band at the bottom of the image.")
        }
    }

    private func currentWatermarkPosition(in size: CGSize) -> CGPoint {
        let x = (size.width * safeHorizontalPosition) + safeGestureTranslation.width
        let y = (size.height * safeVerticalPosition) + safeGestureTranslation.height
        return CGPoint(
            x: min(max(x, 0), size.width),
            y: min(max(y, 0), size.height)
        )
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .updating($gestureTranslation) { value, state, _ in
                state = CGSize(
                    width: value.translation.width.isFinite ? value.translation.width : 0,
                    height: value.translation.height.isFinite ? value.translation.height : 0
                )
            }
            .onEnded { value in
                let deltaX = value.translation.width.isFinite ? value.translation.width : 0
                let deltaY = value.translation.height.isFinite ? value.translation.height : 0
                let newX = min(max((size.width * safeHorizontalPosition) + deltaX, 0), size.width)
                let newY = min(max((size.height * safeVerticalPosition) + deltaY, 0), size.height)
                horizontalPosition = size.width > 0 ? newX / size.width : 0.5
                verticalPosition = size.height > 0 ? newY / size.height : 0.5
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in
                state = value.isFinite ? value : 1
            }
            .onEnded { value in
                let delta = value.isFinite ? Double(value) : 1
                let updatedScale = safeWatermarkScale * delta
                watermarkScale = updatedScale.isFinite ? min(max(updatedScale, 0.6), 4.0) : 1
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .updating($gestureRotation) { value, state, _ in
                if value.degrees.isFinite {
                    state = value
                } else {
                    state = .zero
                }
            }
            .onEnded { value in
                let delta = value.degrees
                guard delta.isFinite else { return }
                let updatedRotation = rotation + delta
                rotation = updatedRotation.isFinite ? updatedRotation : -18
            }
    }

    private func resetWatermarkPlacement() {
        textSize = 34
        watermarkScale = 1
        rotation = -18
        horizontalPosition = 0.5
        verticalPosition = 0.5
    }

    private func tiledPositions(in size: CGSize) -> [CGPoint] {
        let renderFont = fontStyle.uiFont(size: CGFloat(currentWatermarkFontSize))
        let textSize = (watermarkText as NSString).size(withAttributes: [.font: renderFont])
        let cellWidth = max(textSize.width + 42, size.width * 0.32)
        let cellHeight = max(textSize.height + 34, size.height * 0.18)
        let startX = -cellWidth * 0.4
        let startY = -cellHeight * 0.2
        let maxX = size.width + cellWidth
        let maxY = size.height + cellHeight

        var points: [CGPoint] = []
        var rowIndex = 0
        var y = startY
        while y <= maxY {
            let rowOffset = rowIndex.isMultiple(of: 2) ? 0 : cellWidth * 0.5
            var x = startX + rowOffset
            while x <= maxX {
                points.append(CGPoint(x: x, y: y))
                x += cellWidth
            }
            rowIndex += 1
            y += cellHeight
        }
        return points
    }

    private func attributedWatermark(fontSize: CGFloat) -> NSAttributedString {
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(safeShadowRadius > 0 ? 0.35 : 0)
        shadow.shadowBlurRadius = safeShadowRadius
        shadow.shadowOffset = CGSize(width: 0, height: safeShadowRadius * 0.35)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: fontStyle.uiFont(size: fontSize),
            .foregroundColor: colorStyle.uiColor.withAlphaComponent(safeOpacity),
            .strokeColor: UIColor.black.withAlphaComponent(safeOutlineWidth > 0 ? min(0.95, safeOpacity + 0.2) : 0),
            .strokeWidth: -(safeOutlineWidth * 2),
            .shadow: shadow
        ]

        return NSAttributedString(string: watermarkText, attributes: attributes)
    }

    private func drawFloatingWatermark(in context: CGContext, canvasSize: CGSize) {
        let attributed = attributedWatermark(fontSize: CGFloat(safeTextSize * safeWatermarkScale * 2))
        context.saveGState()
        context.translateBy(
            x: canvasSize.width * safeHorizontalPosition,
            y: canvasSize.height * safeVerticalPosition
        )
        context.rotate(by: CGFloat(safeRotation * .pi / 180))
        attributed.draw(at: CGPoint(x: -attributed.size().width / 2, y: -attributed.size().height / 2))
        context.restoreGState()
    }

    private func drawTiledWatermark(in context: CGContext, canvasSize: CGSize) {
        let attributed = attributedWatermark(fontSize: CGFloat(safeTextSize * safeWatermarkScale * 1.7))
        for point in tiledPositions(in: canvasSize) {
            context.saveGState()
            context.translateBy(x: point.x, y: point.y)
            context.rotate(by: CGFloat(safeRotation * .pi / 180))
            attributed.draw(at: CGPoint(x: -attributed.size().width / 2, y: -attributed.size().height / 2))
            context.restoreGState()
        }
    }

    private func drawFooterWatermark(in context: CGContext, canvasSize: CGSize) {
        let barHeight = max(72, CGFloat(safeTextSize * safeWatermarkScale * 1.7) * 1.9)
        let barRect = CGRect(x: 0, y: canvasSize.height - barHeight, width: canvasSize.width, height: barHeight)
        context.saveGState()
        context.setFillColor(UIColor.black.withAlphaComponent(0.22).cgColor)
        context.fill(barRect)

        let attributed = attributedWatermark(fontSize: CGFloat(safeTextSize * safeWatermarkScale * 1.5))
        let drawPoint = CGPoint(
            x: (canvasSize.width - attributed.size().width) / 2,
            y: barRect.midY - (attributed.size().height / 2)
        )
        attributed.draw(at: drawPoint)
        context.restoreGState()
    }

    private func performSave() {
        guard !isSaving else { return }

        guard selectedImage != nil else {
            saveMessage = AppLocalizer.string("Choose a photo to start")
            saveMessageTint = AppColor.warning
            saveAlertTitle = AppLocalizer.string("Save Failed")
            saveAlertMessage = AppLocalizer.string("Choose a photo to start")
            isShowingSaveAlert = true
            return
        }

        guard consumeFeatureUseInSessionIfNeeded() else { return }

        guard let image = renderedImage() else {
            saveMessage = AppLocalizer.string("Could not save right now.")
            saveMessageTint = AppColor.warning
            saveAlertTitle = AppLocalizer.string("Save Failed")
            saveAlertMessage = AppLocalizer.string("Could not save right now.")
            isShowingSaveAlert = true
            return
        }

        AppFeedback.action()
        isSaving = true
        saveMessage = AppLocalizer.string("Saving to Photos...")
        saveMessageTint = AppColor.secondaryText

        photoSaver.save(image) { result in
            isSaving = false
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

    private func fittedImageFrame(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }

        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        let fittedSize: CGSize
        if imageAspect > containerAspect {
            fittedSize = CGSize(width: containerSize.width, height: containerSize.width / imageAspect)
        } else {
            fittedSize = CGSize(width: containerSize.height * imageAspect, height: containerSize.height)
        }

        let origin = CGPoint(
            x: (containerSize.width - fittedSize.width) / 2,
            y: (containerSize.height - fittedSize.height) / 2
        )

        return CGRect(origin: origin, size: fittedSize)
    }
}

private struct WatermarkSecondaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appFont(size: 15, weight: .bold)
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppColor.background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color.opacity(configuration.isPressed ? 0.4 : 1), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct LegacyImagePicker: UIViewControllerRepresentable {
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
        private let parent: LegacyImagePicker

        init(_ parent: LegacyImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first?.itemProvider,
                  item.canLoadObject(ofClass: UIImage.self) else { return }
            item.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    self.parent.image = object as? UIImage
                }
            }
        }
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .appFont(size: 15, weight: .bold)
                    .foregroundColor(AppColor.primaryText)
                Spacer()
                Text(displayValue)
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(AppColor.secondaryText)
            }

            Slider(value: $value, in: range)
        }
    }

    private var displayValue: String {
        let safeValue = value.isFinite ? value : range.lowerBound

        if range.upperBound <= 1.0 {
            return "\(Int((safeValue * 100).rounded()))%"
        }

        if range.lowerBound < 0 {
            return "\(Int(safeValue.rounded()))°"
        }

        return "\(Int(safeValue.rounded()))"
    }
}
