import Combine
import UIKit

final class PhotoLibrarySaver: NSObject, ObservableObject {
    var onComplete: ((Result<Void, Error>) -> Void)?

    func save(_ image: UIImage, onComplete: @escaping (Result<Void, Error>) -> Void) {
        self.onComplete = onComplete
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc
    private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer?) {
        if let error {
            onComplete?(.failure(error))
        } else {
            onComplete?(.success(()))
        }
        onComplete = nil
    }
}
