import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct PhotoProcessingService {
    private let context = CIContext(options: nil)

    func applyEffect(to image: UIImage, config: PhotoEffectConfig, intensity: Double) -> UIImage {
        let clampedIntensity = min(max(intensity, 0), 1)
        guard clampedIntensity > 0 else { return image }
        guard let ciImage = CIImage(image: image) else { return image }

        let compressionMix = config.compression * clampedIntensity
        let downscaleFactor = 1.0 - (0.42 * compressionMix)
        let downscaled = ciImage
            .transformed(by: CGAffineTransform(scaleX: downscaleFactor, y: downscaleFactor))
            .transformed(by: CGAffineTransform(scaleX: 1 / downscaleFactor, y: 1 / downscaleFactor))
            .cropped(to: ciImage.extent)

        let blur = CIFilter.gaussianBlur()
        blur.inputImage = downscaled
        blur.radius = Float(0.1 + (3.2 * config.blur * clampedIntensity))
        guard let blurred = blur.outputImage?.cropped(to: ciImage.extent) else { return image }

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = blurred
        colorControls.brightness = Float(config.exposure * clampedIntensity)
        colorControls.contrast = Float(1.0 + (config.contrast * clampedIntensity))
        colorControls.saturation = Float(1.0 + (config.saturation * clampedIntensity))

        let tempAdjust = CIFilter.temperatureAndTint()
        tempAdjust.inputImage = colorControls.outputImage
        tempAdjust.neutral = CIVector(x: 6500, y: 0)
        let warmthShift = 900 * config.warmth * clampedIntensity
        tempAdjust.targetNeutral = CIVector(x: 6500 - warmthShift, y: 5)

        let grainAlpha = 0.02 + (0.30 * config.grain * clampedIntensity)
        guard let warmed = tempAdjust.outputImage else { return image }
        let withGrain = addGrain(to: warmed, intensity: grainAlpha).cropped(to: ciImage.extent)
        let vignetteApplied = addVignette(to: withGrain, amount: config.vignette * clampedIntensity)

        guard let cgImage = context.createCGImage(vignetteApplied, from: ciImage.extent) else { return image }
        let processed = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        return blend(original: image, processed: processed, amount: clampedIntensity)
    }

    private func addGrain(to image: CIImage, intensity: Double) -> CIImage {
        let random = CIFilter.randomGenerator().outputImage ?? image
        let monochrome = random.applyingFilter(
            "CIColorMatrix",
            parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0.3),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0.3),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0.3),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: intensity),
                "inputBiasVector": CIVector(x: 0.5, y: 0.5, z: 0.5, w: 0)
            ]
        )
        return monochrome.applyingFilter(
            "CISoftLightBlendMode",
            parameters: ["inputBackgroundImage": image]
        )
    }

    private func blend(original: UIImage, processed: UIImage, amount: Double) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = original.scale
        let renderer = UIGraphicsImageRenderer(size: original.size, format: format)
        return renderer.image { _ in
            original.draw(in: CGRect(origin: .zero, size: original.size))
            processed.draw(
                in: CGRect(origin: .zero, size: original.size),
                blendMode: .normal,
                alpha: amount
            )
        }
    }

    private func addVignette(to image: CIImage, amount: Double) -> CIImage {
        let filter = CIFilter.vignette()
        filter.inputImage = image
        filter.intensity = Float(amount * 2.2)
        filter.radius = Float(min(image.extent.width, image.extent.height) * 0.55)
        return filter.outputImage?.cropped(to: image.extent) ?? image
    }
}
