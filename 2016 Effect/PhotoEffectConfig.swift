import Foundation

struct PhotoEffectConfig: Equatable {
    let targetResolution: CGSize
    let blur: Double
    let grain: Double
    let warmth: Double
    let exposure: Double
    let contrast: Double
    let saturation: Double
    let vignette: Double
    let chromaticAberration: Double
    let cornerSoftness: Double
    let shadowNoise: Double
    let bandingNoise: Double
    let toneCurveClip: Double
    let jpegQuality: Double
}
