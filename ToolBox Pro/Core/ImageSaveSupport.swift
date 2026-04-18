import Combine
import Photos
import UIKit

enum PhotoLibrarySaveError: LocalizedError {
    case permissionDenied
    case restricted
    case unknown

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "permissionDenied"
        case .restricted:
            return "restricted"
        case .unknown:
            return "unknown"
        }
    }
}

final class PhotoLibrarySaver: NSObject, ObservableObject {
    func save(_ image: UIImage, onComplete: @escaping (Result<Void, Error>) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized, .limited:
            writeImageToPhotoLibrary(image, onComplete: onComplete)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { updatedStatus in
                DispatchQueue.main.async {
                    switch updatedStatus {
                    case .authorized, .limited:
                        self.writeImageToPhotoLibrary(image, onComplete: onComplete)
                    case .denied:
                        onComplete(.failure(PhotoLibrarySaveError.permissionDenied))
                    case .restricted:
                        onComplete(.failure(PhotoLibrarySaveError.restricted))
                    case .notDetermined:
                        onComplete(.failure(PhotoLibrarySaveError.unknown))
                    @unknown default:
                        onComplete(.failure(PhotoLibrarySaveError.unknown))
                    }
                }
            }
        case .denied:
            onComplete(.failure(PhotoLibrarySaveError.permissionDenied))
        case .restricted:
            onComplete(.failure(PhotoLibrarySaveError.restricted))
        @unknown default:
            onComplete(.failure(PhotoLibrarySaveError.unknown))
        }
    }

    private func writeImageToPhotoLibrary(_ image: UIImage, onComplete: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if let error {
                    onComplete(.failure(error))
                } else if success {
                    onComplete(.success(()))
                } else {
                    onComplete(.failure(PhotoLibrarySaveError.unknown))
                }
            }
        }
    }
}
