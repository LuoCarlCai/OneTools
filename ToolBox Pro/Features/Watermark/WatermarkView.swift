import SwiftUI
import PhotosUI
import Photos
import UIKit

struct WatermarkView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore
    @StateObject private var photoSaver = PhotoLibrarySaver()
    @State private var selectedImage: UIImage?
    @State private var isShowingPicker = false
    @State private var watermarkText = "OneTools"
    @State private var textSize = 34.0
    @State private var watermarkScale = 1.0
    @State private var opacity = 0.55
    @State private var rotation = -18.0
    @State private var horizontalPosition = 0.5
    @State private var verticalPosition = 0.5
    @State private var isLocked = false
    @State private var remainingUses = 0
    @State private var saveMessage = ""
    @State private var saveMessageTint = AppColor.success
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
            summaryPill(title: AppLocalizer.string("Style"), value: AppLocalizer.string("Text"))
            summaryPill(title: AppLocalizer.string("Opacity"), value: "\(Int(opacity * 100))%")
            summaryPill(title: AppLocalizer.string("Angle"), value: "\(Int(rotation))°")
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
                                watermark(in: imageFrame.size)
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

            SliderRow(title: AppLocalizer.string("Opacity"), value: $opacity, range: 0.15...1.0)
            SliderRow(title: AppLocalizer.string("Base Size"), value: $textSize, range: 16...82)

            Button(AppLocalizer.string("Reset Placement")) {
                AppFeedback.selection()
                resetWatermarkPlacement()
            }
            .buttonStyle(WatermarkSecondaryButtonStyle(color: AppColor.primary))

            Text(AppLocalizer.string("Drag the watermark to move it. Pinch to resize and rotate with two fingers directly on the preview."))
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
        Button(AppLocalizer.string("Save")) {
            guard consumeFeatureUseInSessionIfNeeded() else { return }
            guard let image = renderedImage() else { return }
            photoSaver.save(image) { result in
                switch result {
                case .success:
                    AppFeedback.success()
                    saveMessage = AppLocalizer.string("Saved to Photos.")
                    saveMessageTint = AppColor.success
                case .failure:
                    saveMessage = AppLocalizer.string("Could not save right now.")
                    saveMessageTint = AppColor.warning
                }
            }
        }
        .appFont(size: 16, weight: .bold)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .disabled(selectedImage == nil)
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

    private func watermark(in size: CGSize) -> some View {
        Text(watermarkText)
            .appFont(size: currentWatermarkFontSize, weight: .bold)
            .foregroundColor(.white.opacity(opacity))
            .rotationEffect(currentRotation)
            .position(currentWatermarkPosition(in: size))
            .contentShape(Rectangle())
            .gesture(watermarkGesture(in: size))
    }

    private func renderedImage() -> UIImage? {
        guard let image = selectedImage else { return nil }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: textSize * watermarkScale * 2, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(opacity)
            ]
            let attributed = NSAttributedString(string: watermarkText, attributes: textAttributes)
            ctx.cgContext.translateBy(x: image.size.width * horizontalPosition, y: image.size.height * verticalPosition)
            ctx.cgContext.rotate(by: CGFloat(rotation * .pi / 180))
            attributed.draw(at: CGPoint(x: -attributed.size().width / 2, y: -attributed.size().height / 2))
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
        textSize * min(max(Double(gestureScale) * watermarkScale, 0.6), 4.0)
    }

    private var currentRotation: Angle {
        Angle(degrees: rotation) + gestureRotation
    }

    private func currentWatermarkPosition(in size: CGSize) -> CGPoint {
        let x = (size.width * horizontalPosition) + gestureTranslation.width
        let y = (size.height * verticalPosition) + gestureTranslation.height
        return CGPoint(
            x: min(max(x, 0), size.width),
            y: min(max(y, 0), size.height)
        )
    }

    private func watermarkGesture(in size: CGSize) -> some Gesture {
        dragGesture(in: size)
            .simultaneously(with: magnificationGesture)
            .simultaneously(with: rotationGesture)
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .updating($gestureTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let newX = min(max((size.width * horizontalPosition) + value.translation.width, 0), size.width)
                let newY = min(max((size.height * verticalPosition) + value.translation.height, 0), size.height)
                horizontalPosition = size.width > 0 ? newX / size.width : 0.5
                verticalPosition = size.height > 0 ? newY / size.height : 0.5
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                watermarkScale = min(max(watermarkScale * value, 0.6), 4.0)
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .updating($gestureRotation) { value, state, _ in
                state = value
            }
            .onEnded { value in
                rotation += value.degrees
            }
    }

    private func resetWatermarkPlacement() {
        textSize = 34
        watermarkScale = 1
        rotation = -18
        horizontalPosition = 0.5
        verticalPosition = 0.5
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
        if range.upperBound <= 1.0 {
            return "\(Int(value * 100))%"
        }

        if range.lowerBound < 0 {
            return "\(Int(value))°"
        }

        return "\(Int(value))"
    }
}
