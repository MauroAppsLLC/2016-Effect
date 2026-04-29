import Foundation

struct PhotoPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let config: PhotoEffectConfig
}
