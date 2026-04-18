import SwiftUI
import PhotosUI
import UIKit

struct ImageCompressorView: View {
    @EnvironmentObject private var purchaseStore: PurchaseStore
    @StateObject private var photoSaver = PhotoLibrarySaver()
    enum Level: Double, CaseIterable, Identifiable {
        case low = 0.8
        case medium = 0.55
        case high = 0.3
        var id: Double { rawValue }
        var title: String {
            switch self {
            case .low: return AppLocalizer.string("Low")
            case .medium: return AppLocalizer.string("Medium")
            case .high: return AppLocalizer.string("High")
            }
        }
    }

    @State private var isShowingPicker = false
    @State private var selectedImage: UIImage?
    @State private var compressedImage: UIImage?
    @State private var level: Level = .medium
    @State private var originalSizeText = "--"
    @State private var compressedSizeText = "--"
    @State private var isLocked = false
    @State private var remainingUses = 0
    @State private var saveMessage = ""
    @State private var saveMessageTint = AppColor.success
    @State private var saveAlertTitle = ""
    @State private var saveAlertMessage = ""
    @State private var isShowingSaveAlert = false
    @State private var didConsumeTrialInSession = false
    private let premiumFeature: PremiumFeature = .compressor

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: Color(hex: 0x14B8A6), secondaryTint: AppColor.primary)

            ScrollView {
                VStack(spacing: 18) {
                    if isLocked {
                        FeatureLockedCard(feature: premiumFeature)
                    } else {
                        if !purchaseStore.isProUnlocked && remainingUses > 0 {
                            TrialUsageBanner(remainingUses: remainingUses)
                        }

                        infoCard
                        preview
                        sizeSummary
                        controls
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Compressor"))
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
        }
        .onChange(of: compressedImage) { _ in
            saveMessage = ""
        }
        .alert(saveAlertTitle, isPresented: $isShowingSaveAlert) {
            Button(AppLocalizer.string("OK"), role: .cancel) {}
        } message: {
            Text(saveAlertMessage)
        }
        .sheet(isPresented: $isShowingPicker) {
            CompressorImagePicker(image: $selectedImage, originalSizeText: $originalSizeText, compressedImage: $compressedImage, compressedSizeText: $compressedSizeText)
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLocalizer.string("Compress images for sharing"))
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)
            Text(AppLocalizer.string("Choose a photo, compare sizes, and save a lighter copy for uploads or messages."))
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

    private var sizeSummary: some View {
        HStack(spacing: 12) {
            summaryBox(title: AppLocalizer.string("Original"), value: originalSizeText, tint: AppColor.secondaryText)
            summaryBox(title: AppLocalizer.string("Compressed"), value: compressedSizeText, tint: AppColor.primary)
            summaryBox(title: AppLocalizer.string("Level"), value: level.title, tint: AppColor.success)
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
                    Text(AppLocalizer.string("Choose"))
                        .foregroundColor(AppColor.primary)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppColor.background)
                if let image = compressedImage ?? selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(AppColor.primary)
                        Text(AppLocalizer.string("Choose an image to compress."))
                            .foregroundColor(AppColor.secondaryText)
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

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker(AppLocalizer.string("Compression Level"), selection: $level) {
                ForEach(Level.allCases) { level in
                    Text(level.title).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Text("\(originalSizeText)  ->  \(compressedSizeText)")
                .appFont(size: 15, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(AppColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(levelDetail)
                .appFont(size: 13, weight: .regular)
                .foregroundColor(AppColor.secondaryText)

            Button(AppLocalizer.string("Compress")) {
                guard consumeFeatureUseInSessionIfNeeded() else { return }
                AppFeedback.action()
                compress()
            }
            .appFont(size: 16, weight: .bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .disabled(selectedImage == nil)

            Button(AppLocalizer.string("Save")) {
                guard consumeFeatureUseInSessionIfNeeded() else { return }
                if let compressedImage {
                    photoSaver.save(compressedImage) { result in
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
            .appFont(size: 15, weight: .bold)
            .foregroundColor(AppColor.primary)
            .disabled(compressedImage == nil)

            if !saveMessage.isEmpty {
                Text(saveMessage)
                    .appFont(size: 13, weight: .medium)
                    .foregroundColor(saveMessageTint)
                    .frame(maxWidth: .infinity, alignment: .leading)
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

    private func compress() {
        guard let selectedImage,
              let data = selectedImage.jpegData(compressionQuality: level.rawValue),
              let image = UIImage(data: data) else { return }
        compressedImage = image
        compressedSizeText = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    }

    private var levelDetail: String {
        switch level {
        case .low:
            return AppLocalizer.string("Low compression keeps more detail with a larger file size.")
        case .medium:
            return AppLocalizer.string("Medium compression balances quality and size for sharing.")
        case .high:
            return AppLocalizer.string("High compression creates the smallest file for fast upload.")
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

    private func summaryBox(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .appFont(size: 12, weight: .medium)
                .foregroundColor(AppColor.secondaryText)
            Text(value)
                .appFont(size: 16, weight: .bold)
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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
}

private struct CompressorImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var originalSizeText: String
    @Binding var compressedImage: UIImage?
    @Binding var compressedSizeText: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

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
        let parent: CompressorImagePicker
        init(_ parent: CompressorImagePicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    guard let image = object as? UIImage else { return }
                    self.parent.image = image
                    self.parent.compressedImage = nil
                    if let data = image.jpegData(compressionQuality: 1) {
                        self.parent.originalSizeText = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
                    }
                    self.parent.compressedSizeText = "--"
                }
            }
        }
    }
}
