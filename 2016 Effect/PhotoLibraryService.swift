import Photos
import UIKit

enum PhotoLibraryError: LocalizedError {
    case accessDenied
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Photo access is denied. Allow access in Settings."
        case .saveFailed:
            return "Could not save the image. Please try again."
        }
    }
}

struct PhotoLibraryService {
    func saveImageToLibrary(_ image: UIImage) async throws {
        let accessGranted = await requestAddOnlyAccess()
        guard accessGranted else { throw PhotoLibraryError.accessDenied }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { saved, _ in
                if saved {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: PhotoLibraryError.saveFailed)
                }
            }
        }
    }

    private func requestAddOnlyAccess() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let requested = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return requested == .authorized || requested == .limited
        default:
            return false
        }
    }
}
