import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct PhotoProcessingService {
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    func applyEffect(to image: UIImage, config: PhotoEffectConfig, intensity: Double) -> UIImage {
        let t = min(max(intensity, 0), 1)
        guard t > 0 else { return image }
        guard let ciImage = CIImage(image: image) else { return image }

        let originalExtent = ciImage.extent

        // --- Step 1: Resolution degradation ---
        let downscaled = downsample(ciImage, to: config.targetResolution, intensity: t)
        let workingExtent = downscaled.extent

        // --- Step 2: Lens simulation ---
        let lensed = applyLensSimulation(
            to: downscaled,
            extent: workingExtent,
            chromaticAberration: config.chromaticAberration * t,
            cornerSoftness: config.cornerSoftness * t,
            blur: config.blur * t
        )

        // --- Step 3: Sensor noise ---
        let noisy = applySensorNoise(
            to: lensed,
            extent: workingExtent,
            grain: config.grain * t,
            shadowNoise: config.shadowNoise * t,
            bandingNoise: config.bandingNoise * t
        )

        // --- Step 4: ISP emulation ---
        let ispProcessed = applyISPEmulation(
            to: noisy,
            extent: workingExtent,
            config: config,
            intensity: t
        )

        // --- Step 5: Upscale back to original resolution ---
        let upscaled = upsample(ispProcessed, to: originalExtent.size)
        let finalExtent = CGRect(origin: .zero, size: originalExtent.size)

        // --- Step 6: Render to UIImage and apply JPEG round-trip ---
        guard let cgImage = context.createCGImage(upscaled, from: finalExtent) else {
            return image
        }
        let rendered = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        let compressed = jpegRoundTrip(rendered, quality: config.jpegQuality, intensity: t)

        // --- Step 7: Blend with original using intensity ---
        return blend(original: image, processed: compressed, amount: t)
    }

    // MARK: - Step 1: Resolution Degradation

    private func downsample(_ image: CIImage, to targetResolution: CGSize, intensity: Double) -> CIImage {
        let sourceWidth = image.extent.width
        let sourceHeight = image.extent.height

        let targetWidth = targetResolution.width + (sourceWidth - targetResolution.width) * (1.0 - intensity)
        let targetHeight = targetResolution.height + (sourceHeight - targetResolution.height) * (1.0 - intensity)

        let scaleX = targetWidth / sourceWidth
        let scaleY = targetHeight / sourceHeight
        let scale = min(scaleX, scaleY)

        guard scale < 0.99 else { return image }

        let lanczos = CIFilter.lanczosScaleTransform()
        lanczos.inputImage = image
        lanczos.scale = Float(scale)
        lanczos.aspectRatio = Float(scaleX / scaleY)
        return lanczos.outputImage ?? image
    }

    // MARK: - Step 2: Lens Simulation

    private func applyLensSimulation(
        to image: CIImage,
        extent: CGRect,
        chromaticAberration: Double,
        cornerSoftness: Double,
        blur: Double
    ) -> CIImage {
        var result = image

        if chromaticAberration > 0.01 {
            result = applyChromaticAberration(to: result, extent: extent, strength: chromaticAberration)
        }

        if cornerSoftness > 0.01 {
            result = applyCornerSoftness(to: result, extent: extent, strength: cornerSoftness)
        }

        if blur > 0.01 {
            let gaussianBlur = CIFilter.gaussianBlur()
            gaussianBlur.inputImage = result
            gaussianBlur.radius = Float(0.3 + 1.5 * blur)
            result = gaussianBlur.outputImage?.cropped(to: extent) ?? result
        }

        return result
    }

    /// Shifts the red channel outward from center and blue channel inward to simulate
    /// lateral chromatic aberration from a cheap lens element stack.
    private func applyChromaticAberration(to image: CIImage, extent: CGRect, strength: Double) -> CIImage {
        let cx = extent.midX
        let cy = extent.midY
        let pixelShift = 1.0 + strength * 0.003

        let redOnly = image.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])

        let greenOnly = image.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])

        let blueOnly = image.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])

        let redScaled = redOnly
            .transformed(by: CGAffineTransform(translationX: -cx, y: -cy))
            .transformed(by: CGAffineTransform(scaleX: pixelShift, y: pixelShift))
            .transformed(by: CGAffineTransform(translationX: cx, y: cy))
            .cropped(to: extent)

        let blueScaled = blueOnly
            .transformed(by: CGAffineTransform(translationX: -cx, y: -cy))
            .transformed(by: CGAffineTransform(scaleX: 1.0 / pixelShift, y: 1.0 / pixelShift))
            .transformed(by: CGAffineTransform(translationX: cx, y: cy))
            .cropped(to: extent)

        // Recombine channels additively — alpha zeroed above so addition is clean
        let rg = redScaled.applyingFilter("CIAdditionCompositing", parameters: [
            "inputBackgroundImage": greenOnly.cropped(to: extent)
        ])
        let rgb = rg.applyingFilter("CIAdditionCompositing", parameters: [
            "inputBackgroundImage": blueScaled
        ]).cropped(to: extent)

        // Restore alpha to 1.0 so downstream filters work correctly
        return rgb.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ]).cropped(to: extent)
    }

    /// Applies zoom blur masked by a radial gradient so only the edges/corners soften.
    private func applyCornerSoftness(to image: CIImage, extent: CGRect, strength: Double) -> CIImage {
        let zoomBlur = CIFilter.zoomBlur()
        zoomBlur.inputImage = image
        zoomBlur.center = CGPoint(x: extent.midX, y: extent.midY)
        zoomBlur.amount = Float(strength * 4.0)
        guard let blurredFull = zoomBlur.outputImage?.cropped(to: extent) else { return image }

        let radialGradient = CIFilter.radialGradient()
        radialGradient.center = CGPoint(x: extent.midX, y: extent.midY)
        radialGradient.radius0 = Float(min(extent.width, extent.height) * 0.3)
        radialGradient.radius1 = Float(max(extent.width, extent.height) * 0.7)
        radialGradient.color0 = CIColor(red: 0, green: 0, blue: 0, alpha: 1)
        radialGradient.color1 = CIColor(red: 1, green: 1, blue: 1, alpha: 1)

        guard let mask = radialGradient.outputImage?.cropped(to: extent) else { return image }

        return blurredFull.applyingFilter("CIBlendWithMask", parameters: [
            "inputBackgroundImage": image,
            "inputMaskImage": mask
        ]).cropped(to: extent)
    }

    // MARK: - Step 3: Sensor Noise

    private func applySensorNoise(
        to image: CIImage,
        extent: CGRect,
        grain: Double,
        shadowNoise: Double,
        bandingNoise: Double
    ) -> CIImage {
        guard grain > 0.01 else { return image }

        var result = addShadowWeightedGrain(to: image, extent: extent, grain: grain, shadowBias: shadowNoise)

        if bandingNoise > 0.01 {
            result = addBandingNoise(to: result, extent: extent, strength: bandingNoise)
        }

        return result
    }

    /// Generates luminance-only noise weighted toward shadow regions.
    /// Uses CIMultiplyBlendMode so the noise darkens pixels (like real sensor noise)
    /// rather than lightening the whole image.
    private func addShadowWeightedGrain(to image: CIImage, extent: CGRect, grain: Double, shadowBias: Double) -> CIImage {
        let grainStrength = 0.03 + 0.18 * grain

        let random = CIFilter.randomGenerator().outputImage ?? image

        // Convert noise to centered grayscale: values around 0.5 (neutral for overlay blending)
        let monoNoise = random.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0.33, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0.33, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0.33, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputBiasVector": CIVector(x: 0.335, y: 0.335, z: 0.335, w: 0)
        ]).cropped(to: extent)

        let noiseToBlend: CIImage

        if shadowBias > 0.01 {
            let luminance = image.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0.299, y: 0.299, z: 0.299, w: 0),
                "inputGVector": CIVector(x: 0.587, y: 0.587, z: 0.587, w: 0),
                "inputBVector": CIVector(x: 0.114, y: 0.114, z: 0.114, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
            ]).cropped(to: extent)

            let invertedLum = luminance.applyingFilter("CIColorInvert").cropped(to: extent)

            // Mix: (1-shadowBias) * uniform noise + shadowBias * (noise * invertedLuminance)
            // For the shadow-weighted part, blend noise toward 0.5 (neutral) in bright areas
            // by lerping between a flat 0.5 gray and the noise, using inverted luminance as mask
            let neutralGray = CIImage(color: CIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)).cropped(to: extent)

            let shadowWeightedNoise = monoNoise.applyingFilter("CIBlendWithMask", parameters: [
                "inputBackgroundImage": neutralGray,
                "inputMaskImage": invertedLum
            ]).cropped(to: extent)

            // Blend uniform and shadow-weighted noise
            let blendAmount = shadowBias
            noiseToBlend = shadowWeightedNoise.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: blendAmount, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: blendAmount, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: blendAmount, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: 0.5 * (1 - blendAmount), y: 0.5 * (1 - blendAmount), z: 0.5 * (1 - blendAmount), w: 0)
            ]).cropped(to: extent)
        } else {
            noiseToBlend = monoNoise
        }

        // Use dissolve to control noise strength: lerp between the image and the noise-blended version
        // First apply noise via overlay blend
        let noiseApplied = noiseToBlend.applyingFilter("CIOverlayBlendMode", parameters: [
            "inputBackgroundImage": image
        ]).cropped(to: extent)

        // Mix original and noise-applied image by grain strength
        return image.applyingFilter("CIDissolveTransition", parameters: [
            "inputTargetImage": noiseApplied,
            "inputTime": grainStrength
        ]).cropped(to: extent)
    }

    private func addBandingNoise(to image: CIImage, extent: CGRect, strength: Double) -> CIImage {
        let stripes = CIFilter.stripesGenerator()
        stripes.center = CGPoint(x: 0, y: 0)
        stripes.color0 = CIColor(red: 0.49, green: 0.49, blue: 0.49, alpha: 1)
        stripes.color1 = CIColor(red: 0.51, green: 0.51, blue: 0.51, alpha: 1)
        stripes.width = Float(max(1.0, extent.height * 0.003))
        stripes.sharpness = 0.3

        guard let stripesImage = stripes.outputImage?.cropped(to: extent) else { return image }

        let bandingApplied = stripesImage.applyingFilter("CIOverlayBlendMode", parameters: [
            "inputBackgroundImage": image
        ]).cropped(to: extent)

        return image.applyingFilter("CIDissolveTransition", parameters: [
            "inputTargetImage": bandingApplied,
            "inputTime": strength * 0.3
        ]).cropped(to: extent)
    }

    // MARK: - Step 4: ISP Emulation

    private func applyISPEmulation(
        to image: CIImage,
        extent: CGRect,
        config: PhotoEffectConfig,
        intensity: Double
    ) -> CIImage {
        var result = image

        // Tone curve: reduce dynamic range (crush shadows to black, clip highlights to white)
        if config.toneCurveClip > 0.01 {
            result = applyToneCurve(to: result, extent: extent, clip: config.toneCurveClip * intensity)
        }

        // Color adjustments — exposure here is very mild, just slight lift typical of older ISPs
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = result
        colorControls.brightness = Float(config.exposure * intensity * 0.5)
        colorControls.contrast = Float(1.0 + config.contrast * intensity)
        colorControls.saturation = Float(1.0 + config.saturation * intensity)
        result = colorControls.outputImage?.cropped(to: extent) ?? result

        // White balance shift — old cameras had warmer, less accurate auto-WB
        let tempAdjust = CIFilter.temperatureAndTint()
        tempAdjust.inputImage = result
        tempAdjust.neutral = CIVector(x: 6500, y: 0)
        let warmthShift = 600 * config.warmth * intensity
        tempAdjust.targetNeutral = CIVector(x: 6500 - warmthShift, y: 3)
        result = tempAdjust.outputImage?.cropped(to: extent) ?? result

        if config.vignette > 0.01 {
            result = applyVignette(to: result, extent: extent, amount: config.vignette * intensity)
        }

        return result
    }

    /// Reduces dynamic range to emulate older ISPs that couldn't recover shadows or tone-map highlights.
    /// Shadow black point rises, highlight white point drops, midtones stay anchored.
    private func applyToneCurve(to image: CIImage, extent: CGRect, clip: Double) -> CIImage {
        let blackPoint = clip * 0.04
        let whitePoint = 1.0 - clip * 0.03

        let toneCurve = CIFilter.toneCurve()
        toneCurve.inputImage = image
        toneCurve.point0 = CGPoint(x: 0.0, y: blackPoint)
        toneCurve.point1 = CGPoint(x: 0.25, y: 0.22 + blackPoint * 0.3)
        toneCurve.point2 = CGPoint(x: 0.5, y: 0.5)
        toneCurve.point3 = CGPoint(x: 0.75, y: 0.78 - (1.0 - whitePoint) * 0.3)
        toneCurve.point4 = CGPoint(x: 1.0, y: whitePoint)
        return toneCurve.outputImage?.cropped(to: extent) ?? image
    }

    private func applyVignette(to image: CIImage, extent: CGRect, amount: Double) -> CIImage {
        let filter = CIFilter.vignette()
        filter.inputImage = image
        filter.intensity = Float(amount * 2.2)
        filter.radius = Float(min(extent.width, extent.height) * 0.55)
        return filter.outputImage?.cropped(to: extent) ?? image
    }

    // MARK: - Step 5: Upscale

    private func upsample(_ image: CIImage, to targetSize: CGSize) -> CIImage {
        let scaleX = targetSize.width / image.extent.width
        let scaleY = targetSize.height / image.extent.height

        guard scaleX > 1.01 || scaleY > 1.01 else { return image }

        let scale = max(scaleX, scaleY)
        let lanczos = CIFilter.lanczosScaleTransform()
        lanczos.inputImage = image
        lanczos.scale = Float(scale)
        lanczos.aspectRatio = Float(scaleX / scaleY)
        return lanczos.outputImage ?? image
    }

    // MARK: - Step 6: JPEG Round-Trip

    private func jpegRoundTrip(_ image: UIImage, quality: Double, intensity: Double) -> UIImage {
        let effectiveQuality = quality + (1.0 - quality) * (1.0 - intensity)
        guard effectiveQuality < 0.95 else { return image }
        guard let jpegData = image.jpegData(compressionQuality: effectiveQuality) else { return image }
        return UIImage(data: jpegData) ?? image
    }

    // MARK: - Step 7: Blend

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
}
