# 2016 Effect — iOS App Design Doc

## App Summary

**2016 Effect** is an iOS photo editing app that makes modern iPhone photos look like they were taken on older iPhones / nostalgic phone cameras from the mid-2010s.

The core hook:

> “Make your photos look like they were taken in 2016.”

The app lets users take or import photos, apply nostalgic camera presets, adjust intensity, and save/export the edited image.

This app should feel simple, viral, and visually satisfying. It should not feel like a complicated professional photo editor. The product should be fast, fun, and focused on a specific nostalgic aesthetic.

---

# Product Goals

## Primary Goal

Build a simple iOS app where users can:

1. Capture a photo in-app or import one from the camera roll.
2. Apply a “2016” nostalgic photo effect.
3. Preview before/after.
4. Adjust effect intensity.
5. Save the edited photo back to their camera roll.

## Secondary Goals

After MVP:

1. Add more nostalgic presets.
2. Add watermark for free users.
3. Add premium unlock.
4. Add batch photo conversion.
5. Add daily nostalgia prompts.
6. Add photo dump / carousel mode.

---

# Target User

The target user is someone who:

- Likes nostalgic photo aesthetics.
- Thinks modern iPhone photos look too sharp, clinical, or overprocessed.
- Wants their photos to look like old Snapchat memories, Tumblr posts, early Instagram photos, or iPhone 4/5/6 camera roll pictures.
- Wants a simple one-tap transformation, not a complex photo editing suite.

---

# Core Positioning

Do not position this as a generic photo filter app.

Position it specifically as:

> “An app that makes new photos look like old iPhone photos.”

The product should emphasize:

- Nostalgia
- Simplicity
- Imperfect photos
- Old phone camera quality
- 2014–2018 social media aesthetic
- Casual photo dump vibe
- should render photos using specific technical specs that previous cameras had such as pixels to make as accurate as possible

---

# MVP Feature Set

## MVP v1 Features

### 1. Capture or Import Photo

User can either capture a new photo in-app or choose one from their photo library.

Implementation:

- Use `PhotosPicker` from SwiftUI.
- Use `UIImagePickerController` (camera source) for fast v1 camera capture support.
- Load the selected image as `UIImage`.
- Convert to `CIImage` for processing.

### 2. Apply 2016 Preset

The first preset should be called:

**2016**

This preset should make the photo look:

- Slightly lower resolution
- Slightly blurred
- Less sharp
- Mildly compressed
- Warmer
- Slightly overexposed
- Slightly grainy
- More like an older iPhone / Snapchat memory

### 3. Intensity Slider

User can control the effect intensity from `0.0` to `1.0`.

- `0.0` = original photo
- `1.0` = full 2016 effect

### 4. Before / After Preview

User should be able to compare original and edited image.

MVP options:

- Toggle button: “Original” / “Edited”
- Or press-and-hold on image to reveal original

Simplest MVP:

- Add a button that toggles preview mode.

### 5. Save Edited Photo

User can save the edited image to their camera roll.

Implementation:

- Use `UIImageWriteToSavedPhotosAlbum`
- Request photo library permission if needed.
- Show success/error alert.

### 6. Launch Monetization Scope

No premium gating or paywall at launch. v1 focuses on user experience, output quality, and retention validation first.

---

# Post-MVP Features

## 1. Camera Capture

Expand camera capture with custom controls and better ergonomics.

Possible implementation:

- Use `UIImagePickerController` wrapper.
- Later upgrade to `AVFoundation` for custom camera UI.

## 2. Multiple Presets

Potential preset names:

- 2016
- Old Front Cam
- iPhone 4
- iPhone 5s
- iPhone 6
- 2016 Snapchat
- Flashback
- Disposable Night Out
- Tumblr Soft
- Low Battery Camera
- Photo Booth
- Old Mirror Selfie

Each preset should have slightly different values for:

- Blur
- Grain
- Sharpness reduction
- Saturation
- Contrast
- Warmth
- Exposure
- JPEG compression feel
- Optional vignette
- Optional flash effect

## 3. Batch Photo Dump

Premium feature.

User selects multiple photos and applies the same preset to all.

Use case:

> “Make your whole photo dump look like it came from 2016.”

## 4. Watermark

Free users may export with a small watermark:

**2016 Effect**

Premium users can remove watermark.

## 5. Daily Nostalgia Prompt

Examples:

- “Make a mirror selfie look like 2016.”
- “Make today’s lunch look like an old Snapchat memory.”
- “Use flash. No retakes.”
- “Make your room look like Tumblr.”
- “Make your night out look like an old camera roll photo.”

This improves retention.

## 6. Premium Paywall

Potential monetization:

- Free: one preset, watermark, limited saves
- Premium: all presets, no watermark, batch mode, imported photo effects

Possible pricing:

- Monthly: $2.99
- Yearly: $9.99 or $14.99
- Lifetime: $14.99 or $19.99

Monetization should only be enabled after validating engagement quality. A practical trigger is strong edit/export conversion plus healthy D1 retention.

---

# Success Metrics (First 2 Weeks)

- Activation rate: percentage of new users who complete their first edit session.
- Export conversion: percentage of editing sessions with at least one successful save.
- D1 and D7 retention for users who complete an edit.
- Repeat exports per user/session as an output-satisfaction proxy.

---

# Technical Architecture

Use **SwiftUI + MVVM**.

The app should be modular and easy to expand.

Use these layers:

1. **Views**
   - SwiftUI screens and UI components.
   - Should not contain heavy business logic.
   - Bind to ViewModels.

2. **ViewModels**
   - Own screen state.
   - Handle user actions.
   - Call services.
   - Expose published properties to Views.

3. **Models**
   - Data structures such as presets, export result, filter config.

4. **Services**
   - Photo processing
   - Photo library saving
   - Haptics
   - Premium/paywall later
   - Analytics later

5. **Utilities / Extensions**
   - UIImage resizing
   - CIImage helpers
   - Color helpers
   - Watermark drawing

---

# Recommended File Structure

```text
2016Effect/
│
├── App/
│   ├── Effect2016App.swift
│   └── AppConstants.swift
│
├── Core/
│   ├── Models/
│   │   ├── PhotoPreset.swift
│   │   ├── PhotoEffectConfig.swift
│   │   ├── PhotoExportResult.swift
│   │   └── PremiumFeature.swift
│   │
│   ├── Services/
│   │   ├── PhotoProcessingService.swift
│   │   ├── PhotoLibraryService.swift
│   │   ├── HapticService.swift
│   │   ├── WatermarkService.swift
│   │   └── PaywallService.swift
│   │
│   ├── Utilities/
│   │   ├── ImageResizer.swift
│   │   ├── UIImage+Extensions.swift
│   │   ├── CIImage+Extensions.swift
│   │   └── AppLogger.swift
│   │
│   └── Theme/
│       ├── AppTheme.swift
│       ├── AppColors.swift
│       └── AppTypography.swift
│
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   │
│   ├── Editor/
│   │   ├── EditorView.swift
│   │   ├── EditorViewModel.swift
│   │   ├── Components/
│   │   │   ├── PhotoPreviewView.swift
│   │   │   ├── PresetPickerView.swift
│   │   │   ├── IntensitySliderView.swift
│   │   │   └── BeforeAfterToggleView.swift
│   │   └── Presets/
│   │       └── PresetFactory.swift
│   │
│   ├── Camera/
│   │   ├── CameraCaptureView.swift
│   │   └── CameraCaptureViewModel.swift
│   │
│   ├── Paywall/
│   │   ├── PaywallView.swift
│   │   └── PaywallViewModel.swift
│   │
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
│
├── Resources/
│   ├── Assets.xcassets
│   └── PreviewAssets/
│
└── Tests/
    ├── PhotoProcessingServiceTests.swift
    └── PresetFactoryTests.swift