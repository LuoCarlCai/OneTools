import SwiftUI
import PhotosUI
import UIKit

struct ImagePDFView: View {
    private let maxPDFImages = 12

    @State private var isShowingPicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var generatedPDFURL: URL?
    @State private var isShowingShareSheet = false
    @State private var statusMessage = ""
    @State private var statusTint = AppColor.success

    var body: some View {
        ZStack {
            AppPageBackground(primaryTint: AppColor.primary, secondaryTint: Color(hex: 0x0EA5A8))

            ScrollView {
                VStack(spacing: 18) {
                    infoCard
                    previewCard
                    actionCard
                }
                .padding(20)
            }
        }
        .navigationTitle(AppLocalizer.string("Image to PDF"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingPicker) {
            PDFImagePicker(images: $selectedImages, selectionLimit: maxPDFImages)
        }
        .onChange(of: selectedImages) { _ in
            generatedPDFURL = nil
            statusMessage = ""
        }
        .background(
            ShareSheetPresenter(
                isPresented: $isShowingShareSheet,
                items: generatedPDFURL.map { [$0] } ?? []
            )
        )
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLocalizer.string("Create PDF from photos"))
                .appFont(size: 18, weight: .bold)
                .foregroundColor(AppColor.primaryText)

            Text(AppLocalizer.string("Pick multiple images and export a clean PDF for receipts, notes, documents, or screenshots."))
                .appFont(size: 14, weight: .regular)
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(AppLocalizer.string("Select up to %@ images.", "\(maxPDFImages)"))
                .appFont(size: 13, weight: .bold)
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

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(AppLocalizer.string("Selected Images"))
                    .appFont(size: 18, weight: .bold)
                    .foregroundColor(AppColor.primaryText)

                Spacer()

                Text(AppLocalizer.string("%@ pages", "\(selectedImages.count)"))
                    .appFont(size: 13, weight: .bold)
                    .foregroundColor(AppColor.primary)
            }

            if selectedImages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundColor(AppColor.primary)

                    Text(AppLocalizer.string("Choose photos to build a PDF."))
                        .appFont(size: 14, weight: .medium)
                        .foregroundColor(AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 220)
                .background(AppColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Array(selectedImages.prefix(6).enumerated()), id: \.offset) { index, image in
                        thumbnail(image: image, index: index)
                    }
                }

                if selectedImages.count > 6 {
                    Text(AppLocalizer.string("%@ more images selected", "\(selectedImages.count - 6)"))
                        .appFont(size: 13, weight: .medium)
                        .foregroundColor(AppColor.secondaryText)
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
    }

    private var actionCard: some View {
        VStack(spacing: 12) {
            Button {
                AppFeedback.selection()
                isShowingPicker = true
            } label: {
                actionLabel(title: selectedImages.isEmpty ? AppLocalizer.string("Choose Photos") : AppLocalizer.string("Change Photos"), symbol: "photo.on.rectangle")
            }
            .buttonStyle(.plain)

            Button {
                AppFeedback.action()
                createPDF()
            } label: {
                actionLabel(title: AppLocalizer.string("Generate PDF"), symbol: "doc.badge.plus")
            }
            .buttonStyle(.plain)
            .disabled(selectedImages.isEmpty)
            .opacity(selectedImages.isEmpty ? 0.45 : 1)

            if !selectedImages.isEmpty {
                Button {
                    AppFeedback.selection()
                    selectedImages = []
                    generatedPDFURL = nil
                    statusMessage = ""
                } label: {
                    secondaryActionLabel(title: AppLocalizer.string("Clear Photos"), symbol: "trash")
                }
                .buttonStyle(.plain)
            }

            Button {
                AppFeedback.action()
                isShowingShareSheet = generatedPDFURL != nil
            } label: {
                actionLabel(title: AppLocalizer.string("Share PDF"), symbol: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            .disabled(generatedPDFURL == nil)
            .opacity(generatedPDFURL == nil ? 0.45 : 1)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .appFont(size: 13, weight: .bold)
                    .foregroundColor(statusTint)
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

    private func thumbnail(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppColor.background)

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            Text("\(index + 1)")
                .appFont(size: 12, weight: .bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
                .padding(8)
        }
        .aspectRatio(0.74, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func actionLabel(title: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))

            Text(title)
                .appFont(size: 16, weight: .bold)

            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func secondaryActionLabel(title: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))

            Text(title)
                .appFont(size: 15, weight: .bold)

            Spacer()
        }
        .foregroundColor(AppColor.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(AppColor.primary.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func createPDF() {
        guard !selectedImages.isEmpty else { return }

        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let contentRect = pageBounds.insetBy(dx: 36, dy: 36)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDF-QR-Image-Tools-\(UUID().uuidString)")
            .appendingPathExtension("pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)

        do {
            try renderer.writePDF(to: url) { context in
                selectedImages.forEach { image in
                    context.beginPage()
                    UIColor.white.setFill()
                    context.cgContext.fill(pageBounds)
                    image.draw(in: image.aspectFitRect(in: contentRect))
                }
            }

            generatedPDFURL = url
            statusTint = AppColor.success
            statusMessage = AppLocalizer.string("PDF is ready to share.")
            AppFeedback.success()
        } catch {
            generatedPDFURL = nil
            statusTint = Color(hex: 0xF15B6C)
            statusMessage = AppLocalizer.string("Could not create PDF right now.")
        }
    }
}

private struct PDFImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    let selectionLimit: Int

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = selectionLimit
        configuration.preferredAssetRepresentationMode = .compatible

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(images: $images)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        @Binding private var images: [UIImage]

        init(images: Binding<[UIImage]>) {
            _images = images
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else { return }

            var loadedImages = Array<UIImage?>(repeating: nil, count: results.count)
            let group = DispatchGroup()

            for (index, result) in results.enumerated() where result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    loadedImages[index] = object as? UIImage
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.images = loadedImages.compactMap { $0 }
            }
        }
    }
}

private extension UIImage {
    func aspectFitRect(in boundingRect: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return boundingRect }

        let scale = min(boundingRect.width / size.width, boundingRect.height / size.height)
        let fittedSize = CGSize(width: size.width * scale, height: size.height * scale)

        return CGRect(
            x: boundingRect.midX - fittedSize.width / 2,
            y: boundingRect.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }
}
