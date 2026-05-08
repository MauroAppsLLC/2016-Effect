import Foundation

enum PresetFactory {
    static let all: [PhotoPreset] = [
        // Default "2016" feel — targets iPhone 6s-era (12 MP, f/2.2)
        PhotoPreset(
            id: "2016",
            name: "2016",
            config: .init(
                targetResolution: CGSize(width: 4032, height: 3024),
                blur: 0.15,
                grain: 0.18,
                warmth: 0.10,
                exposure: 0.04,
                contrast: -0.08,
                saturation: -0.04,
                vignette: 0.08,
                chromaticAberration: 0.10,
                cornerSoftness: 0.08,
                shadowNoise: 0.20,
                bandingNoise: 0.0,
                toneCurveClip: 0.12,
                jpegQuality: 0.75
            )
        ),

        // iPhone 4 — 5 MP, f/2.8, no OIS, 720p video, plastic lens
        PhotoPreset(
            id: "iphone4",
            name: "iPhone 4",
            config: .init(
                targetResolution: CGSize(width: 2592, height: 1936),
                blur: 0.22,
                grain: 0.26,
                warmth: 0.08,
                exposure: 0.02,
                contrast: -0.12,
                saturation: -0.08,
                vignette: 0.12,
                chromaticAberration: 0.35,
                cornerSoftness: 0.25,
                shadowNoise: 0.35,
                bandingNoise: 0.12,
                toneCurveClip: 0.22,
                jpegQuality: 0.62
            )
        ),

        // iPhone 5s — 8 MP, f/2.2, 1.5µm pixels, True Tone flash
        PhotoPreset(
            id: "iphone5s",
            name: "iPhone 5s",
            config: .init(
                targetResolution: CGSize(width: 3264, height: 2448),
                blur: 0.18,
                grain: 0.20,
                warmth: 0.08,
                exposure: 0.03,
                contrast: -0.08,
                saturation: -0.02,
                vignette: 0.08,
                chromaticAberration: 0.18,
                cornerSoftness: 0.12,
                shadowNoise: 0.22,
                bandingNoise: 0.04,
                toneCurveClip: 0.16,
                jpegQuality: 0.72
            )
        ),

        // iPhone 6 — 8 MP, f/2.2, Focus Pixels, Auto HDR
        PhotoPreset(
            id: "iphone6",
            name: "iPhone 6",
            config: .init(
                targetResolution: CGSize(width: 3264, height: 2448),
                blur: 0.12,
                grain: 0.16,
                warmth: 0.06,
                exposure: 0.02,
                contrast: -0.05,
                saturation: 0.00,
                vignette: 0.06,
                chromaticAberration: 0.12,
                cornerSoftness: 0.08,
                shadowNoise: 0.18,
                bandingNoise: 0.0,
                toneCurveClip: 0.12,
                jpegQuality: 0.76
            )
        ),

        // iPhone 7 — 12 MP, f/1.8, OIS, DCI-P3 wide color
        PhotoPreset(
            id: "iphone7",
            name: "iPhone 7",
            config: .init(
                targetResolution: CGSize(width: 4032, height: 3024),
                blur: 0.06,
                grain: 0.10,
                warmth: 0.04,
                exposure: 0.02,
                contrast: -0.02,
                saturation: 0.03,
                vignette: 0.04,
                chromaticAberration: 0.06,
                cornerSoftness: 0.04,
                shadowNoise: 0.10,
                bandingNoise: 0.0,
                toneCurveClip: 0.08,
                jpegQuality: 0.82
            )
        ),

        // iPhone 8 — 12 MP, f/1.8, OIS, Auto HDR default, improved ISP
        PhotoPreset(
            id: "iphone8",
            name: "iPhone 8",
            config: .init(
                targetResolution: CGSize(width: 4032, height: 3024),
                blur: 0.04,
                grain: 0.07,
                warmth: 0.03,
                exposure: 0.01,
                contrast: 0.00,
                saturation: 0.04,
                vignette: 0.03,
                chromaticAberration: 0.04,
                cornerSoftness: 0.03,
                shadowNoise: 0.06,
                bandingNoise: 0.0,
                toneCurveClip: 0.06,
                jpegQuality: 0.84
            )
        ),

        // Valencia-inspired — warm, faded, slightly compressed
        PhotoPreset(
            id: "valencia",
            name: "Valencia-ish",
            config: .init(
                targetResolution: CGSize(width: 3264, height: 2448),
                blur: 0.10,
                grain: 0.14,
                warmth: 0.16,
                exposure: 0.05,
                contrast: -0.10,
                saturation: -0.02,
                vignette: 0.05,
                chromaticAberration: 0.08,
                cornerSoftness: 0.06,
                shadowNoise: 0.15,
                bandingNoise: 0.0,
                toneCurveClip: 0.12,
                jpegQuality: 0.70
            )
        ),

        // X-Pro-inspired — punchy, contrasty, heavy vignette
        PhotoPreset(
            id: "xpro",
            name: "X-Pro-ish",
            config: .init(
                targetResolution: CGSize(width: 3264, height: 2448),
                blur: 0.08,
                grain: 0.10,
                warmth: 0.12,
                exposure: 0.02,
                contrast: 0.10,
                saturation: 0.14,
                vignette: 0.18,
                chromaticAberration: 0.10,
                cornerSoftness: 0.10,
                shadowNoise: 0.12,
                bandingNoise: 0.0,
                toneCurveClip: 0.16,
                jpegQuality: 0.68
            )
        ),

        // Nashville-inspired — warm, washed-out, low contrast
        PhotoPreset(
            id: "nashville",
            name: "Nashville-ish",
            config: .init(
                targetResolution: CGSize(width: 3264, height: 2448),
                blur: 0.10,
                grain: 0.12,
                warmth: 0.16,
                exposure: 0.06,
                contrast: -0.16,
                saturation: -0.06,
                vignette: 0.06,
                chromaticAberration: 0.08,
                cornerSoftness: 0.06,
                shadowNoise: 0.15,
                bandingNoise: 0.0,
                toneCurveClip: 0.14,
                jpegQuality: 0.70
            )
        )
    ]
}
