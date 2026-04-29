import Combine
import Foundation
import UIKit

enum PostingStep: Int, CaseIterable {
    case select
    case filter
    case adjust
    case export

    var title: String {
        switch self {
        case .select: return "Select"
        case .filter: return "Filter"
        case .adjust: return "Adjust"
        case .export: return "Export"
        }
    }
}

@MainActor
final class EditorViewModel: ObservableObject {
    @Published var intensity: Double = 0.75 {
        didSet { processCurrentImage() }
    }
    @Published var showOriginal = false {
        didSet { analytics.track(showOriginal ? .beforeViewShown : .afterViewShown) }
    }
    @Published var showSavedAlert = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published private(set) var currentStep: PostingStep = .select
    @Published private(set) var originalImage: UIImage?
    @Published private(set) var editedImage: UIImage?
    @Published private(set) var selectedPreset: PhotoPreset = PresetFactory.all[0]

    private let photoProcessor = PhotoProcessingService()
    private let photoLibraryService = PhotoLibraryService()
    private let analytics = AnalyticsService.shared
    private var processingTask: Task<Void, Never>?
    let presets = PresetFactory.all

    var displayImage: UIImage? {
        if showOriginal {
            return originalImage
        }
        return editedImage ?? originalImage
    }

    var canSave: Bool {
        editedImage != nil
    }

    var hasPhoto: Bool {
        originalImage != nil
    }

    func setImage(_ image: UIImage) {
        originalImage = image
        editedImage = image
        showOriginal = false
        currentStep = .filter
        analytics.track(.firstEditStarted)
        analytics.track(.stepFilterOpened)
        processCurrentImage()
    }

    func saveEditedPhoto() async {
        guard let image = editedImage else { return }
        do {
            try await photoLibraryService.saveImageToLibrary(image)
            showSavedAlert = true
            analytics.track(.exportSucceeded)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
            analytics.track(.exportFailed)
        }
    }

    func trackCaptureUsed() {
        analytics.track(.captureUsed)
    }

    func trackImportUsed() {
        analytics.track(.importUsed)
    }

    func selectPreset(_ preset: PhotoPreset) {
        guard selectedPreset != preset else { return }
        selectedPreset = preset
        analytics.track(.presetChanged)
        processCurrentImage()
    }

    func moveToStep(_ step: PostingStep) {
        currentStep = step
        switch step {
        case .select:
            analytics.track(.stepSelectOpened)
        case .filter:
            analytics.track(.stepFilterOpened)
        case .adjust:
            analytics.track(.stepAdjustOpened)
        case .export:
            analytics.track(.stepExportOpened)
        }
    }

    func advanceFromSelect() {
        guard hasPhoto else { return }
        moveToStep(.filter)
    }

    func advanceFromFilter() {
        guard hasPhoto else { return }
        moveToStep(.adjust)
    }

    func advanceFromAdjust() {
        guard hasPhoto else { return }
        moveToStep(.export)
    }

    private func processCurrentImage() {
        processingTask?.cancel()
        guard let originalImage else { return }

        let intensity = intensity
        let preset = selectedPreset
        processingTask = Task.detached(priority: .userInitiated) { [photoProcessor] in
            let processed = photoProcessor.applyEffect(
                to: originalImage,
                config: preset.config,
                intensity: intensity
            )
            await MainActor.run {
                self.editedImage = processed
            }
        }
    }
}
