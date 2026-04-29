import Foundation

enum PresetFactory {
    static let all: [PhotoPreset] = [
        PhotoPreset(
            id: "2016",
            name: "2016",
            config: .init(blur: 0.25, grain: 0.22, warmth: 0.18, exposure: 0.10, contrast: -0.10, saturation: -0.04, vignette: 0.10, compression: 0.16)
        ),
        PhotoPreset(
            id: "iphone4",
            name: "iPhone 4",
            config: .init(blur: 0.34, grain: 0.30, warmth: 0.12, exposure: 0.06, contrast: -0.16, saturation: -0.10, vignette: 0.14, compression: 0.24)
        ),
        PhotoPreset(
            id: "iphone5s",
            name: "iPhone 5s",
            config: .init(blur: 0.26, grain: 0.22, warmth: 0.15, exposure: 0.08, contrast: -0.10, saturation: -0.02, vignette: 0.10, compression: 0.16)
        ),
        PhotoPreset(
            id: "iphone6",
            name: "iPhone 6",
            config: .init(blur: 0.22, grain: 0.18, warmth: 0.12, exposure: 0.07, contrast: -0.06, saturation: 0.00, vignette: 0.08, compression: 0.12)
        ),
        PhotoPreset(
            id: "iphone7",
            name: "iPhone 7",
            config: .init(blur: 0.12, grain: 0.10, warmth: 0.08, exposure: 0.05, contrast: -0.02, saturation: 0.04, vignette: 0.06, compression: 0.08)
        ),
        PhotoPreset(
            id: "iphone8",
            name: "iPhone 8",
            config: .init(blur: 0.10, grain: 0.08, warmth: 0.06, exposure: 0.04, contrast: 0.00, saturation: 0.06, vignette: 0.04, compression: 0.06)
        ),
        PhotoPreset(
            id: "valencia",
            name: "Valencia-ish",
            config: .init(blur: 0.20, grain: 0.16, warmth: 0.24, exposure: 0.12, contrast: -0.14, saturation: -0.02, vignette: 0.06, compression: 0.10)
        ),
        PhotoPreset(
            id: "xpro",
            name: "X-Pro-ish",
            config: .init(blur: 0.14, grain: 0.12, warmth: 0.20, exposure: 0.04, contrast: 0.12, saturation: 0.18, vignette: 0.22, compression: 0.08)
        ),
        PhotoPreset(
            id: "nashville",
            name: "Nashville-ish",
            config: .init(blur: 0.20, grain: 0.14, warmth: 0.26, exposure: 0.14, contrast: -0.20, saturation: -0.08, vignette: 0.08, compression: 0.12)
        )
    ]
}
