import Foundation

enum AnalyticsEvent: String {
    case firstEditStarted
    case captureUsed
    case importUsed
    case presetChanged
    case beforeViewShown
    case afterViewShown
    case stepSelectOpened
    case stepFilterOpened
    case stepAdjustOpened
    case stepExportOpened
    case exportSucceeded
    case exportFailed
}

final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    func track(_ event: AnalyticsEvent) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[Analytics] \(timestamp) event=\(event.rawValue)")
    }
}
