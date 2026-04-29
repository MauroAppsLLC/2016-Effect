# 2016 Effect Camera Research (iPhone 4-8)

This document translates historical iPhone camera behavior into filter tuning targets for `2016 Effect`.

## Why This Matters

The nostalgic look is not one single style. iPhone cameras from 2010-2017 changed in:

- Sensor resolution and pixel pitch
- Aperture and low-light behavior
- Stabilization (none -> OIS)
- HDR and color pipeline aggressiveness
- Contrast, sharpening, and saturation defaults

The app should emulate this progression through presets, while keeping one simple user control: intensity.

## Hardware Baseline Table

| Model | Rear Camera Highlights | Practical Visual Behavior |
|---|---|---|
| iPhone 4 (2010) | 5MP, f/2.8, fixed lens, no OIS, 720p video | Softer detail, lower dynamic range, more visible noise in dim scenes |
| iPhone 5s (2013) | 8MP, 1.5um pixels, f/2.2, dual-tone True Tone flash | Cleaner low-light than earlier models, warmer/more natural flash skin tone |
| iPhone 6/6s era (2014-2015) | 8MP, 1.5um pixels, f/2.2, Focus Pixels AF, Auto HDR | Snappier AF, improved detail/noise balance, still classic 8MP feel |
| iPhone 7 (2016) | 12MP, f/1.8, OIS, improved ISP, wide color (DCI-P3) | Better low-light, stronger color depth, cleaner edges, richer reds/greens |
| iPhone 8 (2017) | 12MP, f/1.8, OIS, updated sensor/ISP, Auto HDR defaults | Higher dynamic range and cleaner tonal rolloff; starts looking less "2016" |

## Source Notes

- iPhone 4: [Apple Support](https://support.apple.com/en-us/112562), [Imaging Resource specs](https://www.imaging-resource.com/cameras/apple-iphone-4-review/specifications/)
- iPhone 5s: [Apple Support](https://support.apple.com/en-us/111973), [CNET camera breakdown](https://www.cnet.com/tech/computing/apple-iphone-5s-camera-in-more-detail/)
- iPhone 6: [Apple Support](https://support.apple.com/en-us/111954), [DXOMARK review](https://www.dxomark.com/apple-iphone-6-and-6-plus-review-bigger-and-better-apple-set-gold-standard-for-smartphone-image-quality)
- iPhone 7: [DXOMARK review](https://www.dxomark.com/apple-iphone-7-camera-review-better-than-ever/)
- iPhone 8: [Apple Support](https://support.apple.com/en-us/111976), [DPReview Auto HDR discussion](https://www.dpreview.com/articles/4326186527/hdr-is-enabled-by-default-on-the-iphone-8-plus-and-that-s-a-really-good-thing)
- Instagram filter interaction history (swipe/filter strength era): [TechCrunch 2014](https://techcrunch.com/2014/06/03/instagram-effects/), [TechCrunch 2012](https://techcrunch.com/2012/12/10/instagram-willow/)

## Era Signatures To Emulate

### 2014-2016 Social Aesthetic

- Slightly reduced micro-contrast
- Mild blur / softness on edges
- Warm tone bias
- Gentle overexposure in highlights
- Fine grain (luminance-biased, not colored noise)
- Light compression feel

### What To Avoid

- Overly crispy sharpening
- Heavy HDR halos
- Extreme saturation
- Modern computational clarity in shadows

## Parameter Mapping (Spec -> Filter Behavior)

Use this mapping when translating hardware history into processing:

- Lower MP era (5-8MP) -> downscale/upsample amount increases
- Smaller/older sensors -> grain and softness increase
- No OIS era -> slight motion softness and lower clarity in dim profiles
- Pre-wide-color era -> keep saturation moderate and color gamut less vivid
- Early Auto HDR era -> conservative shadow lift, avoid deep HDR local contrast

## Preset Calibration Matrix (Starting Values)

All values are normalized for app controls. Final tuning is visual and should be validated against real photo references.

| Preset | Blur | Grain | Warmth | Exposure | Contrast | Saturation | Vignette | Compression |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 2016 (default) | 0.25 | 0.22 | 0.18 | 0.10 | -0.10 | -0.04 | 0.10 | 0.16 |
| iPhone4 | 0.34 | 0.30 | 0.12 | 0.06 | -0.16 | -0.10 | 0.14 | 0.24 |
| iPhone5s | 0.26 | 0.22 | 0.15 | 0.08 | -0.10 | -0.02 | 0.10 | 0.16 |
| iPhone6 | 0.22 | 0.18 | 0.12 | 0.07 | -0.06 | 0.00 | 0.08 | 0.12 |
| iPhone7 | 0.12 | 0.10 | 0.08 | 0.05 | -0.02 | 0.04 | 0.06 | 0.08 |
| iPhone8 | 0.10 | 0.08 | 0.06 | 0.04 | 0.00 | 0.06 | 0.04 | 0.06 |
| ValenciaInspired | 0.20 | 0.16 | 0.24 | 0.12 | -0.14 | -0.02 | 0.06 | 0.10 |
| XProInspired | 0.14 | 0.12 | 0.20 | 0.04 | 0.12 | 0.18 | 0.22 | 0.08 |
| NashvilleInspired | 0.20 | 0.14 | 0.26 | 0.14 | -0.20 | -0.08 | 0.08 | 0.12 |

## Recommended Tuning Ranges

Use these limits to prevent presets from drifting out of era:

- Blur: `0.08...0.36`
- Grain: `0.06...0.32`
- Warmth: `0.04...0.30`
- Exposure: `-0.02...0.18`
- Contrast: `-0.24...0.14`
- Saturation: `-0.14...0.20`
- Vignette: `0.00...0.26`
- Compression: `0.04...0.28`

## UI/UX Implications For Instagram-Style Flow

- Step flow should be: `Select -> Filter -> Adjust -> Export`
- Filter stage must prioritize swipe discovery over deep controls
- Tapping an active filter should reveal strength/intensity
- Before/after should be quick-hold behavior on preview image

## Validation Checklist

- Compare each preset against at least 20 real-world sample photos
- Validate skin tones indoors under warm light
- Validate bright outdoor sky rolloff (avoid modern HDR look)
- Validate low-light noise character (prefer fine luminance noise)
- Check that full-intensity output still looks believable, not stylized parody
